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

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Полное развёртывание проекта (Лаб. 4 + 5 + 6)         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================================================
# 1. СТРУКТУРА ДИРЕКТОРИЙ
# =============================================================================
step "Создание структуры директорий"

mkdir -p src/models
mkdir -p src/controllers
mkdir -p src/views/partials
mkdir -p src/images
mkdir -p src/leaflet
mkdir -p vendor

ok "Все директории созданы"

# =============================================================================
# 2. .env
# =============================================================================
step "Создание .env"
cat > .env << 'EOF'
DB_HOST=db
DB_NAME=clothes_shop
DB_USER=user
DB_PASSWORD=password
DB_ROOT_PASSWORD=rootpassword
EOF
ok ".env"

# =============================================================================
# 3. init.sql
# =============================================================================
step "Создание init.sql"
cat > init.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS clothes_shop;
USE clothes_shop;

CREATE TABLE IF NOT EXISTS users (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    username   VARCHAR(100) NOT NULL UNIQUE,
    email      VARCHAR(255) NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,
    role       VARCHAR(20)  NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT DEFAULT NULL,
    first_name VARCHAR(100),
    last_name  VARCHAR(100),
    phone      VARCHAR(50),
    city       VARCHAR(100),
    address    VARCHAR(255),
    delivery   VARCHAR(100),
    payment    VARCHAR(100),
    total_sum  BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS order_items (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    order_id  INT,
    category  VARCHAR(100),
    size      VARCHAR(50),
    quantity  INT,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);
EOF
ok "init.sql"

# =============================================================================
# 4. composer.json
# =============================================================================
step "Создание composer.json"
cat > composer.json << 'EOF'
{
    "require": {
        "php": ">=8.2",
        "doctrine/orm": "^2.17",
        "doctrine/instantiator": "^1.5",
        "symfony/cache": "^6.4",
        "symfony/var-exporter": "^6.4",
        "fpdf/fpdf": "^1.86",
        "phpoffice/phpspreadsheet": "^2.0"
    },
    "autoload": {
        "psr-4": {
            "App\\Controllers\\": "src/controllers/",
            "App\\": "src/models/"
        }
    },
    "config": {
        "platform": {
            "php": "8.2"
        }
    }
}
EOF
ok "composer.json"

# =============================================================================
# 5. Dockerfile
# =============================================================================
step "Создание Dockerfile"
cat > Dockerfile << 'EOF'
FROM php:8.2-apache
RUN docker-php-ext-install pdo pdo_mysql
COPY src/ /var/www/html/
COPY vendor/ /var/www/html/vendor/
EOF
ok "Dockerfile"

# =============================================================================
# 6. docker-compose.yml
# =============================================================================
step "Создание docker-compose.yml"
cat > docker-compose.yml << 'EOF'
services:
  php:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./src:/var/www/html
      - ./vendor:/var/www/html/vendor
    environment:
      DB_HOST: ${DB_HOST}
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOF
ok "docker-compose.yml"

# =============================================================================
# 7. src/bootstrap.php
# =============================================================================
step "Создание src/bootstrap.php"
cat > src/bootstrap.php << 'EOF'
<?php
session_start();

require_once __DIR__ . '/vendor/autoload.php';

use Doctrine\ORM\ORMSetup;
use Doctrine\ORM\EntityManager;
use Doctrine\DBAL\DriverManager;

$config = ORMSetup::createAttributeMetadataConfiguration(
    paths: [__DIR__ . '/models'],
    isDevMode: true
);

$connection = DriverManager::getConnection([
    'driver'   => 'pdo_mysql',
    'host'     => getenv('DB_HOST'),
    'dbname'   => getenv('DB_NAME'),
    'user'     => getenv('DB_USER'),
    'password' => getenv('DB_PASSWORD'),
], $config);

$entityManager = new EntityManager($connection, $config);
EOF
ok "src/bootstrap.php"

# =============================================================================
# 8. src/Router.php
# =============================================================================
step "Создание src/Router.php"
cat > src/Router.php << 'EOF'
<?php

class Router
{
    private array $routes = [];

    public function get(string $path, array $handler): void
    {
        $this->routes['GET'][$path] = $handler;
    }

    public function post(string $path, array $handler): void
    {
        $this->routes['POST'][$path] = $handler;
    }

    public function dispatch(): void
    {
        $method = $_SERVER['REQUEST_METHOD'];
        $action = $_GET['action'] ?? 'index';

        if (isset($this->routes[$method][$action])) {
            [$controllerClass, $methodName] = $this->routes[$method][$action];
            $controller = new $controllerClass();
            $controller->$methodName();
        } else {
            http_response_code(404);
            echo '<h1>404 — Страница не найдена</h1>';
        }
    }
}
EOF
ok "src/Router.php"

# =============================================================================
# 9. src/index.php
# =============================================================================
step "Создание src/index.php"
cat > src/index.php << 'EOF'
<?php
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/Router.php';
require_once __DIR__ . '/controllers/OrderController.php';
require_once __DIR__ . '/controllers/AuthController.php';
require_once __DIR__ . '/controllers/ReportController.php';

$router = new Router();

$router->get('index',    [\App\Controllers\OrderController::class, 'index']);
$router->post('create',  [\App\Controllers\OrderController::class, 'create']);

$router->get('login',    [\App\Controllers\AuthController::class, 'showLogin']);
$router->post('login',   [\App\Controllers\AuthController::class, 'login']);

$router->get('register', [\App\Controllers\AuthController::class, 'showRegister']);
$router->post('register',[\App\Controllers\AuthController::class, 'register']);

$router->get('logout',   [\App\Controllers\AuthController::class, 'logout']);
$router->get('cabinet',  [\App\Controllers\AuthController::class, 'cabinet']);

$router->get('report_csv',   [\App\Controllers\ReportController::class, 'csv']);
$router->get('report_excel', [\App\Controllers\ReportController::class, 'excel']);
$router->get('report_pdf',   [\App\Controllers\ReportController::class, 'pdf']);

$router->dispatch();
EOF
ok "src/index.php"

# =============================================================================
# 10. src/models/User.php
# =============================================================================
step "Создание src/models/User.php"
cat > src/models/User.php << 'EOF'
<?php
namespace App;

use Doctrine\ORM\Mapping as ORM;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;

#[ORM\Entity]
#[ORM\Table(name: 'users')]
class User
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private int $id;

    #[ORM\Column(length: 100, unique: true)]
    private string $username;

    #[ORM\Column(length: 255, unique: true)]
    private string $email;

    #[ORM\Column(length: 255)]
    private string $password;

    #[ORM\Column(length: 20)]
    private string $role = 'user';

    #[ORM\Column(type: 'datetime')]
    private \DateTime $created_at;

    #[ORM\OneToMany(targetEntity: Order::class, mappedBy: 'user')]
    private Collection $orders;

    public function __construct()
    {
        $this->created_at = new \DateTime();
        $this->orders = new ArrayCollection();
    }

    public function getId(): int              { return $this->id; }
    public function getUsername(): string     { return $this->username; }
    public function getEmail(): string        { return $this->email; }
    public function getPassword(): string     { return $this->password; }
    public function getRole(): string         { return $this->role; }
    public function getCreatedAt(): \DateTime { return $this->created_at; }
    public function getOrders(): Collection  { return $this->orders; }

    public function setUsername(string $v): self { $this->username = $v; return $this; }
    public function setEmail(string $v): self    { $this->email    = $v; return $this; }
    public function setPassword(string $v): self { $this->password = $v; return $this; }
    public function setRole(string $v): self     { $this->role     = $v; return $this; }
}
EOF
ok "src/models/User.php"

# =============================================================================
# 11. src/models/Order.php
# =============================================================================
step "Создание src/models/Order.php"
cat > src/models/Order.php << 'EOF'
<?php
namespace App;

use Doctrine\ORM\Mapping as ORM;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;

#[ORM\Entity]
#[ORM\Table(name: 'orders')]
class Order
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private int $id;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'orders')]
    #[ORM\JoinColumn(name: 'user_id', referencedColumnName: 'id', nullable: true)]
    private ?User $user = null;

    #[ORM\Column(length: 100)]
    private string $first_name;

    #[ORM\Column(length: 100)]
    private string $last_name;

    #[ORM\Column(length: 50)]
    private string $phone;

    #[ORM\Column(length: 100)]
    private string $city;

    #[ORM\Column(length: 255)]
    private string $address;

    #[ORM\Column(length: 100)]
    private string $delivery;

    #[ORM\Column(length: 100)]
    private string $payment;

    #[ORM\Column(type: 'bigint')]
    private int $total_sum = 0;

    #[ORM\Column(type: 'datetime')]
    private \DateTime $created_at;

    #[ORM\OneToMany(targetEntity: OrderItem::class, mappedBy: 'order')]
    private Collection $items;

    public function __construct()
    {
        $this->items = new ArrayCollection();
        $this->created_at = new \DateTime();
    }

    public function getId(): int              { return $this->id; }
    public function getUser(): ?User          { return $this->user; }
    public function getFirstName(): string    { return $this->first_name; }
    public function getLastName(): string     { return $this->last_name; }
    public function getPhone(): string        { return $this->phone; }
    public function getCity(): string         { return $this->city; }
    public function getAddress(): string      { return $this->address; }
    public function getDelivery(): string     { return $this->delivery; }
    public function getPayment(): string      { return $this->payment; }
    public function getTotalSum(): int        { return $this->total_sum; }
    public function getCreatedAt(): \DateTime { return $this->created_at; }
    public function getItems(): Collection   { return $this->items; }

    public function setUser(?User $v): self       { $this->user       = $v; return $this; }
    public function setFirstName(string $v): self { $this->first_name = $v; return $this; }
    public function setLastName(string $v): self  { $this->last_name  = $v; return $this; }
    public function setPhone(string $v): self     { $this->phone      = $v; return $this; }
    public function setCity(string $v): self      { $this->city       = $v; return $this; }
    public function setAddress(string $v): self   { $this->address    = $v; return $this; }
    public function setDelivery(string $v): self  { $this->delivery   = $v; return $this; }
    public function setPayment(string $v): self   { $this->payment    = $v; return $this; }
    public function setTotalSum(int $v): self     { $this->total_sum  = $v; return $this; }
}
EOF
ok "src/models/Order.php"

# =============================================================================
# 12. src/models/OrderItem.php
# =============================================================================
step "Создание src/models/OrderItem.php"
cat > src/models/OrderItem.php << 'EOF'
<?php
namespace App;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
#[ORM\Table(name: 'order_items')]
class OrderItem
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private int $id;

    #[ORM\ManyToOne(targetEntity: Order::class, inversedBy: 'items')]
    #[ORM\JoinColumn(name: 'order_id', referencedColumnName: 'id')]
    private Order $order;

    #[ORM\Column(length: 255)]
    private string $category;

    #[ORM\Column(length: 50)]
    private string $size;

    #[ORM\Column]
    private int $quantity;

    public function getId(): int        { return $this->id; }
    public function getOrder(): Order   { return $this->order; }
    public function getCategory(): string { return $this->category; }
    public function getSize(): string   { return $this->size; }
    public function getQuantity(): int  { return $this->quantity; }

    public function setOrder(Order $v): self     { $this->order    = $v; return $this; }
    public function setCategory(string $v): self { $this->category = $v; return $this; }
    public function setSize(string $v): self     { $this->size     = $v; return $this; }
    public function setQuantity(int $v): self    { $this->quantity = $v; return $this; }
}
EOF
ok "src/models/OrderItem.php"

# =============================================================================
# 13. src/controllers/OrderController.php
# =============================================================================
step "Создание src/controllers/OrderController.php"
cat > src/controllers/OrderController.php << 'EOF'
<?php
namespace App\Controllers;

use App\Order;
use App\OrderItem;
use App\User;

class OrderController
{
    private object $entityManager;

    public function __construct()
    {
        global $entityManager;
        $this->entityManager = $entityManager;
    }

    public function index(): void
    {
        if (empty($_SESSION['user_id'])) {
            header('Location: index.php?action=login');
            exit;
        }

        if ($_SESSION['user_role'] === 'admin') {
            $orders = $this->entityManager
                ->getRepository(Order::class)
                ->findAll();
        } else {
            $user = $this->entityManager
                ->getRepository(User::class)
                ->find($_SESSION['user_id']);
            $orders = $this->entityManager
                ->getRepository(Order::class)
                ->findBy(['user' => $user]);
        }

        require_once __DIR__ . '/../views/index.php';
    }

    public function create(): void
    {
        if (empty($_SESSION['user_id'])) {
            header('Location: index.php?action=login');
            exit;
        }

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            header('Location: index.php?action=index');
            exit;
        }

        $data   = $this->filterInput($_POST);
        $errors = $this->validate($data);

        if (!empty($errors)) {
            $orders     = [];
            $formErrors = $errors;
            require_once __DIR__ . '/../views/index.php';
            return;
        }

        $user = $this->entityManager
            ->getRepository(User::class)
            ->find($_SESSION['user_id']);

        $order = new Order();
        $order->setUser($user)
              ->setFirstName($data['first_name'])
              ->setLastName($data['last_name'])
              ->setPhone($data['phone'])
              ->setCity($data['city'])
              ->setAddress($data['address'])
              ->setDelivery($data['delivery'])
              ->setPayment($data['payment'])
              ->setTotalSum($data['total_sum']);

        $this->entityManager->persist($order);

        foreach ($data['items'] as $itemData) {
            if (empty($itemData['category'])) continue;
            $item = new OrderItem();
            $item->setOrder($order)
                 ->setCategory($itemData['category'])
                 ->setSize($itemData['size'])
                 ->setQuantity($itemData['quantity']);
            $this->entityManager->persist($item);
        }

        try {
            $this->entityManager->flush();
            header('Location: index.php?action=index');
            exit;
        } catch (\Exception $e) {
            $fatalError = 'Ошибка при сохранении: ' . $e->getMessage();
            $orders = [];
            require_once __DIR__ . '/../views/index.php';
        }
    }

    private function filterInput(array $post): array
    {
        $allowedCities   = ['Москва', 'Санкт-Петербург', 'Липецк', 'Воронеж', 'Тамбов'];
        $allowedDelivery = ['Курьер', 'СДЭК', 'Почта России', 'Самовывоз'];
        $allowedPayment  = ['Картой онлайн', 'Наличными при получении', 'Картой при получении'];
        $allowedSizes    = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '25', '30'];

        $filtered = [
            'first_name' => mb_substr(trim(strip_tags($post['first_name'] ?? '')), 0, 100),
            'last_name'  => mb_substr(trim(strip_tags($post['last_name']  ?? '')), 0, 100),
            'phone'      => mb_substr(preg_replace('/[^0-9+\-()\s]/', '', $post['phone'] ?? ''), 0, 50),
            'address'    => mb_substr(trim(strip_tags($post['address'] ?? '')), 0, 255),
            'city'       => in_array($post['city']     ?? '', $allowedCities,   true) ? $post['city']     : '',
            'delivery'   => in_array($post['delivery'] ?? '', $allowedDelivery, true) ? $post['delivery'] : '',
            'payment'    => in_array($post['payment']  ?? '', $allowedPayment,  true) ? $post['payment']  : '',
            'total_sum'  => max(0, (int)($post['total_sum'] ?? 0)),
            'items'      => [],
        ];

        $categories = (array)($post['category'] ?? []);
        $sizes      = (array)($post['size']      ?? []);
        $quantities = (array)($post['quantity']  ?? []);

        foreach ($categories as $i => $cat) {
            $cleanCat  = mb_substr(trim(strip_tags($cat)), 0, 255);
            $cleanSize = in_array($sizes[$i] ?? '', $allowedSizes, true)
                ? $sizes[$i]
                : mb_substr(trim(strip_tags($sizes[$i] ?? '')), 0, 50);
            $filtered['items'][] = [
                'category' => $cleanCat,
                'size'     => $cleanSize,
                'quantity' => max(1, min(99, (int)($quantities[$i] ?? 1))),
            ];
        }

        return $filtered;
    }

    private function validate(array $data): array
    {
        $errors = [];
        if (empty($data['first_name'])) $errors[] = 'Имя не может быть пустым.';
        if (empty($data['last_name']))  $errors[] = 'Фамилия не может быть пустой.';
        if (empty($data['phone']))      $errors[] = 'Телефон не может быть пустым.';
        if (empty($data['city']))       $errors[] = 'Выберите город из списка.';
        if (empty($data['address']))    $errors[] = 'Адрес доставки не может быть пустым.';
        if (empty($data['delivery']))   $errors[] = 'Выберите способ доставки.';
        if (empty($data['payment']))    $errors[] = 'Выберите способ оплаты.';

        $hasItem = false;
        foreach ($data['items'] as $item) {
            if (!empty($item['category'])) { $hasItem = true; break; }
        }
        if (!$hasItem) $errors[] = 'Добавьте хотя бы один товар.';

        return $errors;
    }
}
EOF
ok "src/controllers/OrderController.php"

# =============================================================================
# 14. src/controllers/AuthController.php
# =============================================================================
step "Создание src/controllers/AuthController.php"
cat > src/controllers/AuthController.php << 'EOF'
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
EOF
ok "src/controllers/AuthController.php"

# =============================================================================
# 15. src/controllers/ReportController.php
# =============================================================================
step "Создание src/controllers/ReportController.php"
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

        $pdf = new \FPDF('L', 'mm', 'A4');
        $pdf->AddPage();
        $pdf->SetFont('Arial', 'B', 12);
        $pdf->SetFillColor(0, 0, 0);
        $pdf->SetTextColor(255, 255, 255);
        $pdf->Cell(0, 10, 'Orders Report', 1, 1, 'C', true);
        $pdf->SetTextColor(0, 0, 0);
        $pdf->Ln(3);

        $widths  = [10, 35, 28, 22, 45, 22, 28, 35, 14, 14, 22, 24];
        $headers = ['No', 'Name', 'Phone', 'City', 'Address', 'Delivery',
                    'Payment', 'Item', 'Size', 'Qty', 'Sum (RUB)', 'Date'];

        $pdf->SetFillColor(50, 50, 50);
        $pdf->SetTextColor(255, 255, 255);
        $pdf->SetFont('Arial', 'B', 8);
        foreach ($headers as $i => $h) {
            $pdf->Cell($widths[$i], 7, $h, 1, 0, 'C', true);
        }
        $pdf->Ln();

        $pdf->SetFillColor(245, 245, 245);
        $pdf->SetTextColor(0, 0, 0);
        $pdf->SetFont('Arial', '', 7);
        $fill = false;
        foreach ($rows as $row) {
            foreach ($row as $i => $val) {
                $text = $this->translit((string)$val);
                $pdf->Cell($widths[$i], 6, $text, 1, 0, 'L', $fill);
            }
            $pdf->Ln();
            $fill = !$fill;
        }

        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="orders.pdf"');
        header('Cache-Control: no-cache');
        ob_clean();
        $pdf->Output('D', 'orders.pdf');
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
EOF
ok "src/controllers/ReportController.php"

# =============================================================================
# 16. src/views/partials/header.php
# =============================================================================
step "Создание src/views/partials/header.php"
cat > src/views/partials/header.php << 'EOF'
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
EOF
ok "src/views/partials/header.php"

# =============================================================================
# 17. src/views/partials/footer.php
# =============================================================================
step "Создание src/views/partials/footer.php"
cat > src/views/partials/footer.php << 'EOF'
<script src="leaflet/leaflet.js"></script>
<script>
var map = L.map('map', { attributionControl: false }).setView([52.6088, 39.5994], 12);
L.tileLayer('https://tile.openstreetmap.de/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(map);
var marker = null;
map.on('click', function(e) {
    var lat = e.latlng.lat, lng = e.latlng.lng;
    if (marker) { marker.setLatLng(e.latlng); } else { marker = L.marker(e.latlng).addTo(map); }
    fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lng + '&accept-language=ru')
        .then(function(r) { return r.json(); })
        .then(function(data) {
            var addr = '', a = data.address;
            if (a.road) addr += a.road;
            if (a.house_number) addr += ', ' + a.house_number;
            if (a.city || a.town || a.village) addr += ', ' + (a.city || a.town || a.village);
            document.getElementById('address').value = addr || data.display_name;
            marker.bindPopup(addr || data.display_name).openPopup();
        })
        .catch(function() {
            document.getElementById('address').value = lat.toFixed(5) + ', ' + lng.toFixed(5);
        });
});

var cart = [];
function addToCart(id, name, price) {
    var size = document.getElementById('size-' + id).value;
    var qty  = parseInt(document.getElementById('qty-' + id).value);
    if (isNaN(qty) || qty < 1) qty = 1;
    var existing = cart.find(function(i) { return i.id === id && i.size === size; });
    if (existing) { existing.qty = qty; } else { cart.push({ id: id, name: name, size: size, qty: qty, price: price }); }
    document.getElementById('card-' + id).classList.add('selected');
    var btn = document.querySelector('#card-' + id + ' .btn-add-cart');
    btn.textContent = '✓ В корзине';
    btn.classList.add('in-cart');
    renderCart();
}
function removeFromCart(index) {
    var item = cart[index];
    cart.splice(index, 1);
    var stillInCart = cart.find(function(i) { return i.id === item.id; });
    if (!stillInCart) {
        var card = document.getElementById('card-' + item.id);
        if (card) { card.classList.remove('selected'); var btn = card.querySelector('.btn-add-cart'); btn.textContent = 'В корзину'; btn.classList.remove('in-cart'); }
    }
    renderCart();
}
function renderCart() {
    var list = document.getElementById('cart-list');
    var total = document.getElementById('cart-total');
    var sum = document.getElementById('cart-total-sum');
    if (cart.length === 0) {
        list.innerHTML = '<li><span class="cart-empty-msg">Корзина пуста — выберите товары выше</span></li>';
        total.style.display = 'none'; return;
    }
    var totalSum = 0; list.innerHTML = '';
    cart.forEach(function(item, index) {
        var itemSum = item.price * item.qty; totalSum += itemSum;
        var li = document.createElement('li');
        li.innerHTML = '<span>' + item.name + ' / ' + item.size + ' / ' + item.qty + ' шт.</span>' +
            '<span><b>' + itemSum.toLocaleString('ru-RU') + ' ₽</b>' +
            '<button class="cart-remove" onclick="removeFromCart(' + index + ')" title="Удалить">✕</button></span>';
        list.appendChild(li);
    });
    sum.textContent = totalSum.toLocaleString('ru-RU');
    total.style.display = 'block';
}
function injectCartItems() {
    if (cart.length === 0) { alert('Добавьте хотя бы один товар в корзину!'); window.scrollTo({ top: 0, behavior: 'smooth' }); return false; }
    var container = document.getElementById('cart-hidden-inputs');
    container.innerHTML = '';
    var totalSum = 0;
    cart.forEach(function(item) {
        totalSum += item.price * item.qty;
        function hidden(name, value) { var input = document.createElement('input'); input.type = 'hidden'; input.name = name; input.value = value; container.appendChild(input); }
        hidden('category[]', item.name); hidden('size[]', item.size); hidden('quantity[]', item.qty);
    });
    var ti = document.createElement('input'); ti.type = 'hidden'; ti.name = 'total_sum'; ti.value = totalSum; container.appendChild(ti);
    return true;
}
</script>
</body>
</html>
EOF
ok "src/views/partials/footer.php"

# =============================================================================
# 18. src/views/login.php
# =============================================================================
step "Создание src/views/login.php"
cat > src/views/login.php << 'EOF'
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
EOF
ok "src/views/login.php"

# =============================================================================
# 19. src/views/register.php
# =============================================================================
step "Создание src/views/register.php"
cat > src/views/register.php << 'EOF'
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
EOF
ok "src/views/register.php"

# =============================================================================
# 20. src/views/cabinet.php
# =============================================================================
step "Создание src/views/cabinet.php"
cat > src/views/cabinet.php << 'EOF'
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
EOF
ok "src/views/cabinet.php"

# =============================================================================
# 21. src/views/orders_table.php
# =============================================================================
step "Создание src/views/orders_table.php"
cat > src/views/orders_table.php << 'EOF'
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
EOF
ok "src/views/orders_table.php"

# =============================================================================
# 22. src/views/index.php
# =============================================================================
step "Создание src/views/index.php"
cat > src/views/index.php << 'EOF'
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
EOF
ok "src/views/index.php"

# =============================================================================
# 23. src/style.css
# =============================================================================
step "Создание src/style.css"
cat > src/style.css << 'EOF'
body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; background-color: #ffffff; color: #000000; }
h1 { text-align: center; margin-bottom: 30px; }
h2 { margin-top: 30px; margin-bottom: 15px; border-bottom: 1px solid #000; padding-bottom: 5px; }
h3 { margin-top: 20px; margin-bottom: 10px; }
form { margin: 0; }
div { margin-bottom: 15px; }
input[type="text"], input[type="tel"], input[type="email"] { width: 100%; padding: 8px; margin-top: 5px; border: 1px solid #000; box-sizing: border-box; }
select { width: 100%; padding: 8px; margin-top: 5px; border: 1px solid #000; box-sizing: border-box; }
button { padding: 10px 20px; border: 1px solid #000; background-color: #fff; cursor: pointer; margin-right: 10px; }
button[type="submit"] { background-color: #000; color: #fff; display: block; margin: 0 auto; }
table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 14px; }
table th, table td { border: 1px solid #000; padding: 8px; text-align: left; }
table th { background-color: #000; color: #fff; }
table tr:nth-child(even) { background-color: #f5f5f5; }
.errors { border: 1px solid #cc0000; background: #fff0f0; color: #cc0000; padding: 10px 15px; margin-bottom: 20px; }
.errors ul { margin: 5px 0 0 15px; padding: 0; }

/* Каталог */
.catalog-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 40px; }
.product-card { border: 1px solid #ccc; padding: 15px; display: flex; flex-direction: column; align-items: center; cursor: pointer; transition: border-color 0.2s, box-shadow 0.2s; background: #fff; box-sizing: border-box; }
.product-card:hover { border-color: #000; box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
.product-card.selected { border: 2px solid #000; box-shadow: 0 0 0 2px #000; }
.product-card img { width: 200px; height: 200px; object-fit: contain; display: block; margin-bottom: 12px; flex-shrink: 0; }
.product-card .card-name { font-weight: bold; font-size: 13px; text-align: center; margin-bottom: 6px; width: 100%; min-height: 42px; }
.product-card .card-price-rub { font-size: 15px; font-weight: bold; margin-bottom: 2px; }
.product-card .card-price-foreign { font-size: 12px; color: #666; margin-bottom: 10px; }
.card-controls { width: 100%; margin-top: 8px; }
.card-controls label { font-size: 12px; display: block; margin-bottom: 2px; }
.card-controls select { font-size: 13px; padding: 5px; margin-bottom: 8px; }
.btn-add-cart { width: 100%; padding: 8px 0; background: #000; color: #fff; border: none; cursor: pointer; font-size: 13px; margin-top: 4px; }
.btn-add-cart:hover { background: #333; }
.btn-add-cart.in-cart { background: #4a4a4a; }

/* Корзина */
.cart-summary { border: 1px solid #000; padding: 15px 20px; margin: 20px 0 30px 0; background: #fafafa; }
.cart-summary h3 { margin-top: 0; }
.cart-items-list { list-style: none; padding: 0; margin: 0 0 10px 0; }
.cart-items-list li { display: flex; justify-content: space-between; align-items: center; padding: 6px 0; border-bottom: 1px solid #eee; font-size: 14px; }
.cart-items-list li:last-child { border-bottom: none; }
.cart-remove { background: none; border: none; cursor: pointer; color: #cc0000; font-size: 16px; padding: 0 6px; margin: 0; }
.cart-total { font-weight: bold; font-size: 15px; text-align: right; margin-top: 8px; }
.cart-empty-msg { color: #888; font-size: 14px; }

/* Форма заказа */
.order-form-section { max-width: 600px; margin: 0 auto; }
.order-form-section div { margin-bottom: 15px; }

/* Карта */
#map { height: 350px; width: 100%; margin-top: 8px; border: 1px solid #000; }

/* Навигация */
.main-nav { display: flex; align-items: center; gap: 20px; padding: 10px 0 20px 0; border-bottom: 1px solid #000; margin-bottom: 20px; font-size: 14px; }
.main-nav a { color: #000; text-decoration: none; border-bottom: 1px solid #000; }
.main-nav a:hover { opacity: 0.6; }
.main-nav span { margin-right: auto; font-weight: bold; }

/* Авторизация */
.auth-form { max-width: 400px; margin: 0 auto; }
.auth-form p { margin-top: 15px; font-size: 14px; }

/* Личный кабинет */
.cabinet-info { border: 1px solid #000; padding: 15px 20px; margin-bottom: 30px; max-width: 400px; }
.cabinet-info p { margin: 5px 0; }

/* Кнопки отчётов */
.report-buttons { display: flex; align-items: center; gap: 12px; margin: 20px 0 15px 0; flex-wrap: wrap; }
.report-buttons span { font-size: 14px; font-weight: bold; }
.btn-report { display: inline-block; padding: 8px 18px; text-decoration: none; font-size: 13px; font-weight: bold; border: none; cursor: pointer; transition: opacity 0.2s; }
.btn-report:hover { opacity: 0.8; }
.btn-csv { background-color: #217346; color: #ffffff; }
.btn-excel { background-color: #1d6f42; color: #ffffff; }
.btn-pdf { background-color: #cc0000; color: #ffffff; }
EOF
ok "src/style.css"

# =============================================================================
# Итог
# =============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗"
echo    "║   Проект создан полностью с нуля!                        ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo ""
echo "  1. Установить зависимости (на хосте, не в Docker):"
echo "       composer install"
echo "       composer require fpdf/fpdf phpoffice/phpspreadsheet"
echo ""
echo "  2. Скачать Leaflet вручную:"
echo "       curl -L https://unpkg.com/leaflet@1.9.4/dist/leaflet.js -o src/leaflet/leaflet.js"
echo "       curl -L https://unpkg.com/leaflet@1.9.4/dist/leaflet.css -o src/leaflet/leaflet.css"
echo ""
echo "  3. Положить картинки товаров в src/images/:"
echo "       item1.png ... item8.png"
echo ""
echo "  4. Запустить контейнеры:"
echo "       docker-compose up --build -d"
echo ""
echo "  5. Открыть в браузере:"
echo "       http://localhost:8080/index.php?action=login"
echo ""
echo -e "${CYAN}Структура проекта:${NC}"
find . -not -path './vendor/*' -not -name '*.lock' -not -path './.git/*' | sort | sed 's|[^/]*/|  |g'
