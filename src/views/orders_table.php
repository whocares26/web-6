<?php if (!empty($_SESSION['user_id'])): ?>
<div class="report-buttons">
    <span>Скачать отчёт:</span>
    <a href="index.php?action=report_csv"   class="btn-report btn-csv">⬇ CSV</a>
    <a href="index.php?action=report_excel" class="btn-report btn-excel">⬇ Excel</a>
    <a href="index.php?action=report_pdf"   class="btn-report btn-pdf">⬇ PDF</a>
</div>
<?php endif; ?>
<table>
    <tr><th>№</th><th>Имя</th><th>Фамилия</th><th>Телефон</th><th>Город</th><th>Адрес</th><th>Доставка</th><th>Оплата</th><th>Категория</th><th>Размер</th><th>Кол-во</th><th>Сумма</th><th>Дата</th></tr>
    <?php if (empty($orders)): ?>
        <tr><td colspan="13" style="text-align:center">Заказов пока нет</td></tr>
    <?php else: ?>
        <?php foreach ($orders as $order): ?>
            <?php foreach ($order->getItems() as $item): ?>
                <tr>
                    <td><?= htmlspecialchars((string)$order->getId()) ?></td>
                    <td><?= htmlspecialchars($order->getFirstName()) ?></td>
                    <td><?= htmlspecialchars($order->getLastName()) ?></td>
                    <td><?= htmlspecialchars($order->getPhone()) ?></td>
                    <td><?= htmlspecialchars($order->getCity()) ?></td>
                    <td><?= htmlspecialchars($order->getAddress()) ?></td>
                    <td><?= htmlspecialchars($order->getDelivery()) ?></td>
                    <td><?= htmlspecialchars($order->getPayment()) ?></td>
                    <td><?= htmlspecialchars($item->getCategory()) ?></td>
                    <td><?= htmlspecialchars($item->getSize()) ?></td>
                    <td><?= htmlspecialchars((string)$item->getQuantity()) ?></td>
                    <td><?= number_format($order->getTotalSum(), 0, '.', ' ') ?> ₽</td>
                    <td><?= $order->getCreatedAt()->format('Y-m-d H:i:s') ?></td>
                </tr>
            <?php endforeach; ?>
        <?php endforeach; ?>
    <?php endif; ?>
</table>
