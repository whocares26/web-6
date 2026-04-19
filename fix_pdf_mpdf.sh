#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

step() { echo -e "\n${CYAN}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✔ $1${NC}"; }
err()  { echo -e "  ${RED}✖ $1${NC}"; exit 1; }

if [ ! -f "docker-compose.yml" ]; then
    err "Запусти скрипт из корня проекта (там где docker-compose.yml)"
fi

# =============================================================================
# 1. Установить mPDF
# =============================================================================
step "Установка mPDF (поддержка UTF-8 и русского языка)"

composer require mpdf/mpdf

ok "mPDF установлен"

# =============================================================================
# 2. Перезаписать ReportController.php
# =============================================================================
step "Обновление src/controllers/ReportController.php"

cat > src/controllers/ReportController.php << 'EOF'
<?php
namespace App\Controllers;

use App\Order;
use App\User;

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
                    number_format($order->getTotalSum(), 0, '.', ' ') . ' руб',
                    $order->getCreatedAt()->format('d.m.Y H:i'),
                ];
            }
        }
        return $rows;
    }

    private function headers(): array
    {
        return ['№', 'ФИО', 'Телефон', 'Город', 'Адрес', 'Доставка',
                'Оплата', 'Товар', 'Размер', 'Кол-во', 'Сумма', 'Дата'];
    }

    // =========================================================================
    // CSV
    // =========================================================================
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

    // =========================================================================
    // Excel
    // =========================================================================
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

    // =========================================================================
    // PDF — mPDF с полной поддержкой UTF-8 и русского языка
    // =========================================================================
    public function pdf(): void
    {
        $orders  = $this->getOrders();
        $rows    = $this->flattenOrders($orders);
        $headers = $this->headers();

        $mpdf = new \Mpdf\Mpdf([
            'orientation' => 'L',
            'margin_left'  => 8,
            'margin_right' => 8,
            'margin_top'   => 10,
            'margin_bottom'=> 10,
        ]);

        $mpdf->SetTitle('Отчёт по заказам');

        // Стили
        $css = '
            body { font-family: DejaVuSans; font-size: 8pt; }
            h1 { font-size: 13pt; text-align: center; background: #000;
                 color: #fff; padding: 5px; margin-bottom: 10px; }
            table { width: 100%; border-collapse: collapse; font-size: 7pt; }
            th { background: #333; color: #fff; padding: 4px 3px;
                 border: 1px solid #666; text-align: center;
                 font-weight: bold; white-space: nowrap; }
            td { padding: 3px; border: 1px solid #ccc;
                 vertical-align: top; word-wrap: break-word; }
            tr:nth-child(even) td { background: #f5f5f5; }
        ';

        // HTML таблица
        $html = '<h1>Отчёт по заказам</h1>';
        $html .= '<table>';
        $html .= '<thead><tr>';
        foreach ($headers as $h) {
            $html .= '<th>' . htmlspecialchars($h) . '</th>';
        }
        $html .= '</tr></thead>';
        $html .= '<tbody>';

        foreach ($rows as $row) {
            $html .= '<tr>';
            foreach ($row as $val) {
                $html .= '<td>' . htmlspecialchars((string)$val) . '</td>';
            }
            $html .= '</tr>';
        }

        $html .= '</tbody></table>';

        $mpdf->WriteHTML($css, \Mpdf\HTMLParserMode::HEADER_CSS);
        $mpdf->WriteHTML($html, \Mpdf\HTMLParserMode::HTML_BODY);

        $output = $mpdf->Output('', 'S');

        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="orders.pdf"');
        header('Content-Length: ' . strlen($output));
        header('Cache-Control: no-cache');

        echo $output;
        exit;
    }
}
EOF

ok "src/controllers/ReportController.php"

# =============================================================================
# 3. Пересобрать контейнер с обновлённым vendor
# =============================================================================
step "Пересборка Docker контейнера"

docker-compose down
docker-compose up --build -d

ok "Контейнеры перезапущены"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗"
echo    "║   Готово! PDF теперь с русским языком.               ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Открой http://localhost:8080/index.php?action=cabinet"
echo "и нажми кнопку PDF."
