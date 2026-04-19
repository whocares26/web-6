<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Магазин одежды</title>
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="leaflet/leaflet.css"/>
    <style>
        #map { height: 350px; width: 100%; margin-top: 8px; border: 1px solid #000; }
    </style>
</head>
<body>
<nav class="main-nav">
    <?php if (!empty($_SESSION['user_id'])): ?>
        <span>👤 <?= htmlspecialchars($_SESSION['username']) ?>
            <?= $_SESSION['user_role'] === 'admin' ? ' (Администратор)' : '' ?>
        </span>
        <a href="index.php?action=cabinet">Личный кабинет</a>
        <a href="index.php?action=index">Магазин</a>
        <a href="index.php?action=logout">Выйти</a>
    <?php else: ?>
        <a href="index.php?action=login">Войти</a>
        <a href="index.php?action=register">Регистрация</a>
    <?php endif; ?>
</nav>
