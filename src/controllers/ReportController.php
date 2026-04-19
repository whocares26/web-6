<?php
namespace App\Controllers;

use App\Order;
use App\User;
use FPDF;

class ReportController
{
    private object $entityManager;

    public function __construct()
    {
        global $entityManager;
        $this->entityManager = $entityManager;
    }

    private function getOrders(): array
    {
        if (empty($_SESSION['user_id'])) {
            header('Location: index.php?action=login');
            exit;
        }

        if ($_SESSION['user_role'] === 'admin') {
            return $this->entityManager
                ->getRepository(Order::class)
                ->findAll();
        }

        $user = $this->entityManager
            ->getRepository(User::class)
            ->find($_SESSION['user_id']);

        return $this->entityManager
            ->getRepository(Order::class)
            ->findBy(['user' => $user]);
    }

    private function flattenOrders(array $orders): array
    {
        $rows = [];
        foreach ($orders as $order) {
            foreach ($order->getItems() as $item) {
                $rows[] = [
                    $order->getId(),
                    $order->getFirstName() . ' ' . $order->getLastName(),
                    $order->getPhone(),
                    $order->getCity(),
                    $order->getAddress(),
                    $order->getDelivery(),
                    $order->getPayment(),
                    $item->getCategory(),
                    $item->getSize(),
                    $item->getQuantity(),
                    $order->getTotalSum(),
                    $order->getCreatedAt()->format('d.m.Y H:i'),
                ];
            }
        }
        return $rows;
    }

    private function headers(): array
    {
        return ['№', 'ФИО', 'Телефон', 'Город', 'Адрес', 'Доставка',
                'Оплата', 'Товар', 'Размер', 'Кол-во', 'Сумма (руб)', 'Дата'];
    }

    public function csv(): void
    {
        $orders = $this->getOrders();
        $rows   = $this->flattenOrders($orders);

        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="orders.csv"');
        header('Cache-Control: no-cache');

        $out = fopen('php://output', 'w');
        fputs($out, "\xEF\xBB\xBF");
        fputcsv($out, $this->headers(), ';');
        foreach ($rows as $row) {
            fputcsv($out, $row, ';');
        }
        fclose($out);
        exit;
    }

    public function excel(): void
    {
        $orders = $this->getOrders();
        $rows   = $this->flattenOrders($orders);

        $spreadsheet = new \PhpOffice\PhpSpreadsheet\Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Заказы');

        $headers = $this->headers();
        $cols    = ['A','B','C','D','E','F','G','H','I','J','K','L'];

        foreach ($headers as $i => $h) {
            $cell = $cols[$i] . '1';
            $sheet->setCellValue($cell, $h);
            $sheet->getStyle($cell)->getFont()->setBold(true);
            $sheet->getStyle($cell)->getFill()
                ->setFillType(\PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID)
                ->getStartColor()->setARGB('FF000000');
            $sheet->getStyle($cell)->getFont()->getColor()->setARGB('FFFFFFFF');
        }

        foreach ($rows as $ri => $row) {
            foreach ($row as $ci => $val) {
                $sheet->setCellValue($cols[$ci] . ($ri + 2), $val);
            }
        }

        foreach ($cols as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }

        header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        header('Content-Disposition: attachment; filename="orders.xlsx"');
        header('Cache-Control: no-cache');

        $writer = new \PhpOffice\PhpSpreadsheet\Writer\Xlsx($spreadsheet);
        $writer->save('php://output');
        exit;
    }

    public function pdf(): void
{
    $orders = $this->getOrders();
    $rows   = $this->flattenOrders($orders);

    $pdf = new \Fpdf\Fpdf('L', 'mm', 'A4');
    $pdf->SetMargins(8, 8, 8);
    $pdf->AddPage();
    $pdf->SetFont('Arial', 'B', 12);
    $pdf->SetFillColor(0, 0, 0);
    $pdf->SetTextColor(255, 255, 255);
    $pdf->Cell(0, 10, 'Orders Report', 1, 1, 'C', true);
    $pdf->SetTextColor(0, 0, 0);
    $pdf->Ln(3);

    $widths  = [7, 25, 22, 14, 42, 18, 36, 40, 10, 8, 20, 24];
    $headers = ['No','Name','Phone','City','Address','Delivery',
                'Payment','Item','Size','Qty','Sum (RUB)','Date'];

    // Шапка
    $pdf->SetFillColor(50, 50, 50);
    $pdf->SetTextColor(255, 255, 255);
    $pdf->SetFont('Arial', 'B', 7);
    foreach ($headers as $i => $h) {
        $pdf->Cell($widths[$i], 7, $h, 1, 0, 'C', true);
    }
    $pdf->Ln();

    // Строки с переносом текста
    $pdf->SetTextColor(0, 0, 0);
    $pdf->SetFont('Arial', '', 6.5);
    $lineH = 4.5;
    $fill  = false;

    foreach ($rows as $row) {
        // Считаем высоту строки — по самой высокой ячейке
        $maxLines = 1;
        foreach ($row as $i => $val) {
            $text  = $this->translit((string)$val);
            $words = explode(' ', $text);
            $lines = 1;
            $cur   = '';
            foreach ($words as $word) {
                $test = $cur === '' ? $word : $cur . ' ' . $word;
                if ($pdf->GetStringWidth($test) > $widths[$i] - 2) {
                    $lines++;
                    $cur = $word;
                } else {
                    $cur = $test;
                }
            }
            if ($lines > $maxLines) $maxLines = $lines;
        }
        $rowH = $maxLines * $lineH + 2;

        // Если не влезает на страницу — новая страница
        if ($pdf->GetY() + $rowH > $pdf->GetPageHeight() - 10) {
            $pdf->AddPage();
            $pdf->SetFont('Arial', 'B', 7);
            $pdf->SetFillColor(50, 50, 50);
            $pdf->SetTextColor(255, 255, 255);
            foreach ($headers as $i => $h) {
                $pdf->Cell($widths[$i], 7, $h, 1, 0, 'C', true);
            }
            $pdf->Ln();
            $pdf->SetFont('Arial', '', 6.5);
            $pdf->SetTextColor(0, 0, 0);
        }

        $x = $pdf->GetX();
        $y = $pdf->GetY();
        $fillColor = $fill ? [245, 245, 245] : [255, 255, 255];

        foreach ($row as $i => $val) {
            $text = $this->translit((string)$val);
            $pdf->SetFillColor($fillColor[0], $fillColor[1], $fillColor[2]);
            $pdf->MultiCell($widths[$i], $lineH, $text, 1, 'L', true);
            // Возвращаем курсор на начало строки
            $x += $widths[$i];
            $pdf->SetXY($x, $y);
        }
        $pdf->SetXY(8, $y + $rowH);
        $fill = !$fill;
    }

    $output = $pdf->Output('S');

    header('Content-Type: application/pdf');
    header('Content-Disposition: attachment; filename="orders.pdf"');
    header('Content-Length: ' . strlen($output));
    header('Cache-Control: no-cache');

    echo $output;
    exit;
}
    private function translit(string $text): string
    {
        $map = [
            'А'=>'A','Б'=>'B','В'=>'V','Г'=>'G','Д'=>'D','Е'=>'E','Ё'=>'Yo',
            'Ж'=>'Zh','З'=>'Z','И'=>'I','Й'=>'J','К'=>'K','Л'=>'L','М'=>'M',
            'Н'=>'N','О'=>'O','П'=>'P','Р'=>'R','С'=>'S','Т'=>'T','У'=>'U',
            'Ф'=>'F','Х'=>'Kh','Ц'=>'Ts','Ч'=>'Ch','Ш'=>'Sh','Щ'=>'Sch',
            'Ъ'=>'','Ы'=>'Y','Ь'=>'','Э'=>'E','Ю'=>'Yu','Я'=>'Ya',
            'а'=>'a','б'=>'b','в'=>'v','г'=>'g','д'=>'d','е'=>'e','ё'=>'yo',
            'ж'=>'zh','з'=>'z','и'=>'i','й'=>'j','к'=>'k','л'=>'l','м'=>'m',
            'н'=>'n','о'=>'o','п'=>'p','р'=>'r','с'=>'s','т'=>'t','у'=>'u',
            'ф'=>'f','х'=>'kh','ц'=>'ts','ч'=>'ch','ш'=>'sh','щ'=>'sch',
            'ъ'=>'','ы'=>'y','ь'=>'','э'=>'e','ю'=>'yu','я'=>'ya','₽'=>'RUB',
        ];
        return strtr($text, $map);
    }
}
