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
