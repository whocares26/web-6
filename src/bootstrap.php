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
