<?php
$source = $_GET['source'] ?? 'logs/ops.log';

// Validación defectuosa: comprueba una cadena, pero no normaliza el path.
if (strpos($source, 'logs/') === false) {
    http_response_code(400);
    exit('Illegal source specified');
}

$baseDirectory = dirname(__DIR__);
$target = $baseDirectory . '/' . $source;

if (!is_file($target) || !is_readable($target)) {
    http_response_code(404);
    exit('Record not found');
}

header('Content-Type: text/plain; charset=utf-8');
readfile($target);
