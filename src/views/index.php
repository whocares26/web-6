<?php require_once __DIR__ . '/partials/header.php'; ?>

<h1>Магазин — Оформление заказа</h1>

<?php if (!empty($formErrors)): ?>
    <div class="errors"><strong>Исправьте ошибки:</strong><ul><?php foreach ($formErrors as $err): ?><li><?= htmlspecialchars($err) ?></li><?php endforeach; ?></ul></div>
<?php endif; ?>
<?php if (!empty($fatalError)): ?>
    <div class="errors"><?= htmlspecialchars($fatalError) ?></div>
<?php endif; ?>

<?php
$products = [
    ['id'=>1,'img'=>'images/item1.png','name'=>'Сумка Hermes Birkin 25 Havane GHW','price_rub'=>9153000,'price_usd'=>113000,'price_eur'=>97372,'sizes'=>['25']],
    ['id'=>2,'img'=>'images/item2.png','name'=>'Сумка Hermes Birkin Cargo 25 Vert Moyen PHW','price_rub'=>3928500,'price_usd'=>48500,'price_eur'=>41792,'sizes'=>['25']],
    ['id'=>3,'img'=>'images/item3.png','name'=>'Сумка Hermes Birkin 30 HSS Biscuit/Craie GHW','price_rub'=>2592000,'price_usd'=>32000,'price_eur'=>27574,'sizes'=>['30']],
    ['id'=>4,'img'=>'images/item4.png','name'=>'Сумка Hermes Birkin 30 Black Togo PHW','price_rub'=>2592000,'price_usd'=>32000,'price_eur'=>27574,'sizes'=>['30']],
    ['id'=>5,'img'=>'images/item5.png','name'=>'Hermes Пиджак из шерсти и шелка','price_rub'=>441600,'price_usd'=>4800,'price_eur'=>4420,'sizes'=>['XS','S','M','L','XL','XXL']],
    ['id'=>6,'img'=>'images/item6.png','name'=>'Hermes Двусторонняя кожаная куртка','price_rub'=>1702000,'price_usd'=>18500,'price_eur'=>17040,'sizes'=>['XS','S','M','L','XL','XXL']],
    ['id'=>7,'img'=>'images/item7.png','name'=>'Hermes Кожаная куртка','price_rub'=>1104000,'price_usd'=>12000,'price_eur'=>11050,'sizes'=>['XS','S','M','L','XL','XXL']],
    ['id'=>8,'img'=>'images/item8.png','name'=>'Zilly Бомбер из кожи страуса','price_rub'=>2300000,'price_usd'=>25000,'price_eur'=>23020,'sizes'=>['XS','S','M','L','XL','XXL']],
];
$bags     = array_slice($products, 0, 4);
$clothing = array_slice($products, 4, 4);
?>

<h2>Сумки</h2>
<div class="catalog-row">
<?php foreach ($bags as $p): ?>
    <div class="product-card" id="card-<?= $p['id'] ?>">
        <img src="<?= htmlspecialchars($p['img']) ?>" alt="<?= htmlspecialchars($p['name']) ?>">
        <div class="card-name"><?= htmlspecialchars($p['name']) ?></div>
        <div class="card-price-rub"><?= number_format($p['price_rub'], 0, '.', ' ') ?> ₽</div>
        <div class="card-price-foreign">$<?= number_format($p['price_usd'], 0, '.', ',') ?> / €<?= number_format($p['price_eur'], 0, '.', ',') ?></div>
        <div class="card-controls">
            <label>Размер:</label>
            <select id="size-<?= $p['id'] ?>"><?php foreach ($p['sizes'] as $s): ?><option value="<?= $s ?>"><?= $s ?></option><?php endforeach; ?></select>
            <label>Количество:</label>
            <input type="number" id="qty-<?= $p['id'] ?>" value="1" min="1" max="99" style="width:100%;padding:5px;border:1px solid #000;box-sizing:border-box;font-size:13px;">
            <button class="btn-add-cart" onclick="addToCart(<?= $p['id'] ?>, <?= htmlspecialchars(json_encode($p['name'])) ?>, <?= $p['price_rub'] ?>)">В корзину</button>
        </div>
    </div>
<?php endforeach; ?>
</div>

<h2>Одежда</h2>
<div class="catalog-row">
<?php foreach ($clothing as $p): ?>
    <div class="product-card" id="card-<?= $p['id'] ?>">
        <img src="<?= htmlspecialchars($p['img']) ?>" alt="<?= htmlspecialchars($p['name']) ?>">
        <div class="card-name"><?= htmlspecialchars($p['name']) ?></div>
        <div class="card-price-rub"><?= number_format($p['price_rub'], 0, '.', ' ') ?> ₽</div>
        <div class="card-price-foreign">$<?= number_format($p['price_usd'], 0, '.', ',') ?> / €<?= number_format($p['price_eur'], 0, '.', ',') ?></div>
        <div class="card-controls">
            <label>Размер:</label>
            <select id="size-<?= $p['id'] ?>"><?php foreach ($p['sizes'] as $s): ?><option value="<?= $s ?>"><?= $s ?></option><?php endforeach; ?></select>
            <label>Количество:</label>
            <input type="number" id="qty-<?= $p['id'] ?>" value="1" min="1" max="99" style="width:100%;padding:5px;border:1px solid #000;box-sizing:border-box;font-size:13px;">
            <button class="btn-add-cart" onclick="addToCart(<?= $p['id'] ?>, <?= htmlspecialchars(json_encode($p['name'])) ?>, <?= $p['price_rub'] ?>)">В корзину</button>
        </div>
    </div>
<?php endforeach; ?>
</div>

<div class="cart-summary">
    <h3>Ваша корзина</h3>
    <ul class="cart-items-list" id="cart-list"><li><span class="cart-empty-msg">Корзина пуста — выберите товары выше</span></li></ul>
    <div class="cart-total" id="cart-total" style="display:none">Итого: <span id="cart-total-sum">0</span> ₽</div>
</div>

<div class="order-form-section">
    <h2>Оформление заказа</h2>
    <form action="index.php?action=create" method="POST" onsubmit="return injectCartItems()">
        <div>Имя: *<br><input type="text" name="first_name" required></div>
        <div>Фамилия: *<br><input type="text" name="last_name" required></div>
        <div>Телефон: *<br><input type="tel" name="phone" required></div>
        <div>Город: *<br>
            <select name="city" required>
                <option value="">-- Выберите --</option>
                <?php foreach (['Москва','Санкт-Петербург','Липецк','Воронеж','Тамбов'] as $city): ?>
                    <option value="<?= $city ?>"><?= $city ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div>Адрес доставки: *<br>
            <input type="text" name="address" id="address" placeholder="Кликните на карту или введите вручную" required>
            <div id="map"></div>
            <small style="color:#555">Кликните на карту — адрес заполнится автоматически</small>
        </div>
        <div>Способ доставки: *<br>
            <select name="delivery" required>
                <option value="">-- Выберите --</option>
                <?php foreach (['Курьер','СДЭК','Почта России','Самовывоз'] as $d): ?>
                    <option value="<?= $d ?>"><?= $d ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div>Способ оплаты: *<br>
            <select name="payment" required>
                <option value="">-- Выберите --</option>
                <?php foreach (['Картой онлайн','Наличными при получении','Картой при получении'] as $p): ?>
                    <option value="<?= $p ?>"><?= $p ?></option>
                <?php endforeach; ?>
            </select>
        </div>
        <div id="cart-hidden-inputs"></div>
        <button type="submit">Оформить заказ</button>
    </form>
</div>

<h2>Все заказы</h2>
<?php require __DIR__ . '/orders_table.php'; ?>
<?php require_once __DIR__ . '/partials/footer.php'; ?>
