<?php require_once __DIR__ . '/partials/header.php'; ?>
<h1>Личный кабинет</h1>
<div class="cabinet-info">
    <p><strong>Имя пользователя:</strong> <?= htmlspecialchars($user->getUsername()) ?></p>
    <p><strong>Email:</strong> <?= htmlspecialchars($user->getEmail()) ?></p>
    <p><strong>Роль:</strong> <?= $user->getRole() === 'admin' ? 'Администратор' : 'Пользователь' ?></p>
    <p><strong>Дата регистрации:</strong> <?= $user->getCreatedAt()->format('d.m.Y H:i') ?></p>
</div>
<h2>Мои заказы</h2>
<div class="report-buttons">
    <span>Скачать отчёт:</span>
    <a href="index.php?action=report_csv"   class="btn-report btn-csv">⬇ CSV</a>
    <a href="index.php?action=report_excel" class="btn-report btn-excel">⬇ Excel</a>
    <a href="index.php?action=report_pdf"   class="btn-report btn-pdf">⬇ PDF</a>
</div>
<?php if (empty($orders)): ?>
    <p>У вас пока нет заказов. <a href="index.php?action=index">Перейти в магазин</a></p>
<?php else: ?>
    <table>
        <tr><th>№</th><th>Дата</th><th>Город</th><th>Адрес</th><th>Доставка</th><th>Оплата</th><th>Товары</th><th>Сумма</th></tr>
        <?php foreach ($orders as $order): ?>
            <tr>
                <td><?= $order->getId() ?></td>
                <td><?= $order->getCreatedAt()->format('d.m.Y H:i') ?></td>
                <td><?= htmlspecialchars($order->getCity()) ?></td>
                <td><?= htmlspecialchars($order->getAddress()) ?></td>
                <td><?= htmlspecialchars($order->getDelivery()) ?></td>
                <td><?= htmlspecialchars($order->getPayment()) ?></td>
                <td><?php foreach ($order->getItems() as $item): ?><?= htmlspecialchars($item->getCategory()) ?> (<?= htmlspecialchars($item->getSize()) ?>, <?= $item->getQuantity() ?> шт.)<br><?php endforeach; ?></td>
                <td><?= number_format($order->getTotalSum(), 0, '.', ' ') ?> ₽</td>
            </tr>
        <?php endforeach; ?>
    </table>
<?php endif; ?>
<?php require_once __DIR__ . '/partials/footer.php'; ?>
