<?php
session_start();

if (!($_SESSION['active'] ?? false)) {
    // Error intencional: se envía el redirect, pero falta exit.
    header('Location: /signin.php');
}
?>
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Nightfall Operations Console</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 820px; margin: 4rem auto; padding: 0 1rem; color: #1d2630; }
        .panel { border: 1px solid #cfd8e3; border-radius: 14px; padding: 1.5rem; }
        code { background: #edf2f7; padding: .15rem .35rem; border-radius: 4px; }
        a { color: #155eef; }
    </style>
</head>
<body>
    <main class="panel">
        <h1>Operations Console</h1>
        <p>Herramientas internas del observatorio.</p>
        <nav>
            <ul>
                <li><a href="/vault/records.php?source=logs/ops.log">Operational records</a></li>
                <li><a href="/vault/">Vault index</a></li>
            </ul>
        </nav>
        <p><small>Build channel: <code>nightfall-console</code></small></p>
    </main>
</body>
</html>
