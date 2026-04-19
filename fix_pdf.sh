#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

step() { echo -e "\n${CYAN}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✔ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠ $1${NC}"; }
err()  { echo -e "  ${RED}✖ $1${NC}"; exit 1; }

if [ ! -f "docker-compose.yml" ]; then
    err "Запусти скрипт из корня проекта (там где docker-compose.yml)"
fi

# =============================================================================
# 1. Скачать шрифт DejaVuSans (поддерживает кириллицу)
# =============================================================================
step "Скачивание шрифта DejaVuSans с поддержкой кириллицы"

mkdir -p src/fonts

if curl -fsSL "https://github.com/dejavu-fonts/dejavu-fonts/raw/master/ttf/DejaVuSans.ttf" \
    -o src/fonts/DejaVuSans.ttf 2>/dev/null; then
    ok "DejaVuSans.ttf скачан"
else
    warn "Не удалось скачать шрифт через интернет"
    warn "Попробуем найти его в системе..."

    FOUND=""
    for path in \
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
        /usr/share/fonts/dejavu/DejaVuSans.ttf \
        /usr/share/fonts/TTF/DejaVuSans.ttf; do
        if [ -f "$path" ]; then
            cp "$path" src/fonts/DejaVuSans.ttf
            FOUND="$path"
            break
        fi
    done

    if [ -n "$FOUND" ]; then
        ok "Шрифт скопирован из $FOUND"
    else
        warn "Шрифт не найден. Установим через apt..."
        sudo apt-get install -y fonts-dejavu-core 2>/dev/null || true
        for path in \
            /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
            /usr/share/fonts/dejavu/DejaVuSans.ttf; do
            if [ -f "$path" ]; then
                cp "$path" src/fonts/DejaVuSans.ttf
                ok "Шрифт установлен и скопирован"
                FOUND="$path"
                break
            fi
        done
        if [ -z "$FOUND" ]; then
            err "Не удалось получить шрифт. Проверь интернет-соединение."
        fi
    fi
fi

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
    // PDF — кириллица через DejaVuSans TTF, одинаковая высота строк
    // =========================================================================
    public function pdf(): void
    {
        $orders  = $this->getOrders();
        $rows    = $this->flattenOrders($orders);
        $fontDir = __DIR__ . '/../fonts/';

        $pdf = new \Fpdf\Fpdf('L', 'mm', 'A4');
        $pdf->SetMargins(8, 8, 8);

        // Подключаем DejaVuSans для кириллицы
        $pdf->AddFont('DejaVu', '', 'DejaVuSans.ttf', true);
        $pdf->AddFont('DejaVu', 'B', 'DejaVuSans.ttf', true);
        putenv('FPDF_FONTPATH=' . $fontDir);

        $pdf->AddPage();

        // Заголовок документа
        $pdf->SetFont('DejaVu', 'B', 12);
        $pdf->SetFillColor(0, 0, 0);
        $pdf->SetTextColor(255, 255, 255);
        $pdf->Cell(0, 10, $this->u('Отчёт по заказам'), 1, 1, 'C', true);
        $pdf->SetTextColor(0, 0, 0);
        $pdf->Ln(3);

        $widths  = [7, 25, 22, 14, 42, 18, 35, 40, 10, 8, 20, 25];
        $headers = $this->headers();
        $lineH   = 4.5;

        // Шапка таблицы
        $pdf->SetFillColor(50, 50, 50);
        $pdf->SetTextColor(255, 255, 255);
        $pdf->SetFont('DejaVu', 'B', 7);
        foreach ($headers as $i => $h) {
            $pdf->Cell($widths[$i], 7, $this->u($h), 1, 0, 'C', true);
        }
        $pdf->Ln();

        // Строки данных
        $pdf->SetTextColor(0, 0, 0);
        $pdf->SetFont('DejaVu', '', 6.5);
        $fill = false;

        foreach ($rows as $row) {

            // ── Шаг 1: вычислить высоту каждой ячейки ──
            $cellHeights = [];
            foreach ($row as $i => $val) {
                $text  = $this->u((string)$val);
                $lines = $this->countLines($pdf, $text, $widths[$i] - 2);
                $cellHeights[$i] = $lines * $lineH + 1;
            }
            $rowH = max($cellHeights);

            // ── Шаг 2: перенос страницы ──
            if ($pdf->GetY() + $rowH > $pdf->GetPageHeight() - 10) {
                $pdf->AddPage();
                $pdf->SetFont('DejaVu', 'B', 7);
                $pdf->SetFillColor(50, 50, 50);
                $pdf->SetTextColor(255, 255, 255);
                foreach ($headers as $i => $h) {
                    $pdf->Cell($widths[$i], 7, $this->u($h), 1, 0, 'C', true);
                }
                $pdf->Ln();
                $pdf->SetFont('DejaVu', '', 6.5);
                $pdf->SetTextColor(0, 0, 0);
            }

            // ── Шаг 3: рисуем строку ──
            $startX = $pdf->GetX();
            $startY = $pdf->GetY();
            $curX   = $startX;
            $fillColor = $fill ? [245, 245, 245] : [255, 255, 255];

            foreach ($row as $i => $val) {
                $text = $this->u((string)$val);
                $pdf->SetFillColor($fillColor[0], $fillColor[1], $fillColor[2]);

                // Рисуем фон и рамку нужной высоты
                $pdf->Rect($curX, $startY, $widths[$i], $rowH, 'FD');

                // Пишем текст с переносом, начиная с той же позиции
                $pdf->SetXY($curX + 1, $startY + 1);
                $pdf->MultiCell($widths[$i] - 2, $lineH, $text, 0, 'L', false);

                $curX += $widths[$i];
            }

            // Переводим курсор на следующую строку
            $pdf->SetXY($startX, $startY + $rowH);
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

    // Конвертация UTF-8 → cp1252 для FPDF
    private function u(string $text): string
    {
        return iconv('UTF-8', 'cp1252//TRANSLIT//IGNORE', $text) ?: $text;
    }

    // Подсчёт строк которые займёт текст в ячейке заданной ширины
    private function countLines(\Fpdf\Fpdf $pdf, string $text, float $width): int
    {
        if (trim($text) === '') return 1;
        $words = preg_split('/\s+/', trim($text));
        $lines = 1;
        $cur   = '';
        foreach ($words as $word) {
            $test = $cur === '' ? $word : $cur . ' ' . $word;
            if ($pdf->GetStringWidth($test) > $width) {
                $lines++;
                $cur = $word;
            } else {
                $cur = $test;
            }
        }
        return max(1, $lines);
    }
}
EOF

ok "src/controllers/ReportController.php"

# =============================================================================
# 3. Добавить шрифт в Dockerfile чтобы он копировался в контейнер
# =============================================================================
step "Обновление Dockerfile"

cat > Dockerfile << 'EOF'
FROM php:8.2-apache
RUN docker-php-ext-install pdo pdo_mysql
COPY src/ /var/www/html/
COPY vendor/ /var/www/html/vendor/
EOF

ok "Dockerfile"

# =============================================================================
# 4. Пересобрать контейнер чтобы шрифт попал внутрь
# =============================================================================
step "Пересборка Docker контейнера"

docker-compose down
docker-compose up --build -d

ok "Контейнеры перезапущены"

# =============================================================================
# Итог
# =============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗"
echo    "║   Готово! PDF теперь с кириллицей и ровными строками ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Что изменено:"
echo "  src/fonts/DejaVuSans.ttf          ← шрифт с кириллицей"
echo "  src/controllers/ReportController.php ← обновлён"
echo ""
echo "Открой http://localhost:8080/index.php?action=cabinet"
echo "и нажми кнопку PDF."
EOF
