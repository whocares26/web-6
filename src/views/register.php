<?php require_once __DIR__ . '/partials/header.php'; ?>
<h1>Регистрация</h1>
<?php if (!empty($errors)): ?>
    <div class="errors"><ul><?php foreach ($errors as $e): ?><li><?= htmlspecialchars($e) ?></li><?php endforeach; ?></ul></div>
<?php endif; ?>
<div class="auth-form">
    <form action="index.php?action=register" method="POST">
        <div>Имя пользователя:<br><input type="text" name="username" value="<?= htmlspecialchars($_POST['username'] ?? '') ?>" required></div>
        <div>Email:<br><input type="email" name="email" value="<?= htmlspecialchars($_POST['email'] ?? '') ?>" required></div>
        <div>Пароль (минимум 6 символов):<br><input type="password" name="password" required></div>
        <div>Повторите пароль:<br><input type="password" name="confirm" required></div>
        <button type="submit">Зарегистрироваться</button>
    </form>
    <p>Уже есть аккаунт? <a href="index.php?action=login">Войти</a></p>
</div>
<?php require_once __DIR__ . '/partials/footer.php'; ?>
