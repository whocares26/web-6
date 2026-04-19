<?php require_once __DIR__ . '/partials/header.php'; ?>
<h1>Вход</h1>
<?php if (!empty($errors)): ?>
    <div class="errors"><ul><?php foreach ($errors as $e): ?><li><?= htmlspecialchars($e) ?></li><?php endforeach; ?></ul></div>
<?php endif; ?>
<div class="auth-form">
    <form action="index.php?action=login" method="POST">
        <div>Имя пользователя:<br><input type="text" name="username" value="<?= htmlspecialchars($_POST['username'] ?? '') ?>" required></div>
        <div>Пароль:<br><input type="password" name="password" required></div>
        <button type="submit">Войти</button>
    </form>
    <p>Нет аккаунта? <a href="index.php?action=register">Зарегистрироваться</a></p>
</div>
<?php require_once __DIR__ . '/partials/footer.php'; ?>
