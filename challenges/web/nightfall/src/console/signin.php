<?php
session_start();

$knownUsers = ['archivist', 'navigator', 'curator'];
$notice = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = strtolower(trim($_POST['username'] ?? ''));

    if (in_array($username, $knownUsers, true)) {
        $notice = 'Invalid password.';
    } else {
        $notice = 'Invalid username or password.';
    }
}
?>
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Nightfall Console | Sign in</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 560px; margin: 4rem auto; padding: 0 1rem; color: #1d2630; }
        .card { border: 1px solid #cfd8e3; border-radius: 14px; padding: 1.5rem; }
        .notice { padding: .75rem; background: #fff4e5; border: 1px solid #f0c36d; }
        input, button { font: inherit; padding: .55rem .7rem; margin: .25rem 0; }
    </style>
</head>
<body>
    <main class="card">
        <h1>Operations Console</h1>
        <p>Autenticación requerida.</p>
        <?php if ($notice !== ''): ?>
            <p class="notice"><?= htmlspecialchars($notice, ENT_QUOTES, 'UTF-8') ?></p>
        <?php endif; ?>
        <form method="post">
            <p><label>Usuario<br><input name="username" required></label></p>
            <p><label>Contraseña<br><input type="password" name="password" required></label></p>
            <button type="submit">Ingresar</button>
        </form>
    </main>
</body>
</html>
