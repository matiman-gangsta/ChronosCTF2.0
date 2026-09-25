<?php
$uploadDir = __DIR__ . '/attachments/';
$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isset($_FILES['upload']) || $_FILES['upload']['error'] !== UPLOAD_ERR_OK) {
        $error = 'No se recibió un archivo válido.';
    } else {
        $originalName = basename($_FILES['upload']['name']);

        if (!preg_match('/^[A-Za-z0-9._-]{1,64}$/', $originalName)) {
            $error = 'El nombre contiene caracteres no permitidos.';
        } elseif ($_FILES['upload']['size'] > 200000) {
            $error = 'El archivo supera el tamaño máximo permitido (200 KB).';
        } else {
            $extension = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
            $blockedExtensions = [
                'php', 'php3', 'php4', 'php5', 'php7', 'phtml', 'pht', 'phar', 'htaccess'
            ];

            if (in_array($extension, $blockedExtensions, true)) {
                $error = 'Ese tipo de archivo está bloqueado.';
            } elseif (!move_uploaded_file($_FILES['upload']['tmp_name'], $uploadDir . $originalName)) {
                $error = 'No fue posible guardar el archivo.';
            } else {
                $safeName = htmlspecialchars($originalName, ENT_QUOTES, 'UTF-8');
                $linkName = rawurlencode($originalName);
                $message = 'Archivo recibido: <a href="/attachments/' . $linkName . '">' . $safeName . '</a>';
            }
        }
    }
}
?>
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Transferencia | ConfigGate</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 760px; margin: 4rem auto; padding: 0 1rem; color: #17202a; }
        .card { border: 1px solid #d5d8dc; border-radius: 12px; padding: 1.5rem; box-shadow: 0 6px 20px #00000010; }
        .ok { color: #126b36; }
        .error { color: #a61b1b; }
        a { color: #155eef; }
        input, button { font: inherit; padding: .55rem .7rem; }
        button { cursor: pointer; }
    </style>
</head>
<body>
    <main class="card">
        <p><a href="/">&larr; Volver</a></p>
        <h1>Transferir documento</h1>
        <p>Sube un archivo de configuración para que el equipo lo revise.</p>

        <?php if ($message !== ''): ?>
            <p class="ok"><?= $message ?></p>
        <?php endif; ?>
        <?php if ($error !== ''): ?>
            <p class="error"><?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?></p>
        <?php endif; ?>

        <form method="post" enctype="multipart/form-data">
            <p><input type="file" name="upload" required></p>
            <button type="submit">Enviar archivo</button>
        </form>
    </main>
</body>
</html>
