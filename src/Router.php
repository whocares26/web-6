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
