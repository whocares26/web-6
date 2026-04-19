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
