<?php
namespace App\Controllers;

use App\User;

class AuthController
{
    private object $entityManager;

    public function __construct()
    {
        global $entityManager;
        $this->entityManager = $entityManager;
    }

    public function showLogin(): void
    {
        require_once __DIR__ . '/../views/login.php';
    }

    public function login(): void
    {
        $username = trim($_POST['username'] ?? '');
        $password = $_POST['password'] ?? '';
        $errors   = [];

        if (empty($username)) $errors[] = 'Введите имя пользователя.';
        if (empty($password)) $errors[] = 'Введите пароль.';

        if (empty($errors)) {
            $user = $this->entityManager
                ->getRepository(User::class)
                ->findOneBy(['username' => $username]);

            if (!$user || !password_verify($password, $user->getPassword())) {
                $errors[] = 'Неверное имя пользователя или пароль.';
            } else {
                $_SESSION['user_id']   = $user->getId();
                $_SESSION['username']  = $user->getUsername();
                $_SESSION['user_role'] = $user->getRole();
                header('Location: index.php?action=index');
                exit;
            }
        }

        require_once __DIR__ . '/../views/login.php';
    }

    public function showRegister(): void
    {
        require_once __DIR__ . '/../views/register.php';
    }

    public function register(): void
    {
        $username = trim($_POST['username'] ?? '');
        $email    = trim($_POST['email']    ?? '');
        $password = $_POST['password']      ?? '';
        $confirm  = $_POST['confirm']       ?? '';
        $errors   = [];

        if (empty($username)) $errors[] = 'Введите имя пользователя.';
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL))
            $errors[] = 'Введите корректный email.';
        if (strlen($password) < 6)
            $errors[] = 'Пароль должен быть не менее 6 символов.';
        if ($password !== $confirm)
            $errors[] = 'Пароли не совпадают.';

        if (empty($errors)) {
            $existing = $this->entityManager
                ->getRepository(User::class)
                ->findOneBy(['username' => $username]);
            if ($existing) $errors[] = 'Пользователь с таким именем уже существует.';
        }

        if (empty($errors)) {
            $user = new User();
            $user->setUsername($username)
                 ->setEmail($email)
                 ->setPassword(password_hash($password, PASSWORD_BCRYPT));

            $this->entityManager->persist($user);
            $this->entityManager->flush();

            $_SESSION['user_id']   = $user->getId();
            $_SESSION['username']  = $user->getUsername();
            $_SESSION['user_role'] = $user->getRole();
            header('Location: index.php?action=index');
            exit;
        }

        require_once __DIR__ . '/../views/register.php';
    }

    public function logout(): void
    {
        session_destroy();
        header('Location: index.php?action=login');
        exit;
    }

    public function cabinet(): void
    {
        if (empty($_SESSION['user_id'])) {
            header('Location: index.php?action=login');
            exit;
        }

        $user = $this->entityManager
            ->getRepository(User::class)
            ->find($_SESSION['user_id']);

        $orders = $this->entityManager
            ->getRepository(\App\Order::class)
            ->findBy(['user' => $user]);

        require_once __DIR__ . '/../views/cabinet.php';
    }
}
