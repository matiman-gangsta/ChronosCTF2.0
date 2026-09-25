from app import create_app


def make_client():
    app = create_app({"TESTING": True})
    return app.test_client()


def test_health_endpoint():
    response = make_client().get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_default_document_is_rendered():
    response = make_client().get("/")
    assert response.status_code == 200
    assert b"Bienvenido al nodo documental 03" in response.data
    assert b"FLAG{" not in response.data


def test_public_document_can_be_opened():
    response = make_client().get("/?view=network-notes.txt")
    assert response.status_code == 200
    assert b"INFRASTRUCTURE NOTES" in response.data
    assert b"FLAG{" not in response.data


def test_non_txt_extension_is_rejected():
    response = make_client().get("/?view=../../app.py")
    assert response.status_code == 200
    assert b"Formato no admitido" in response.data
    assert b"from flask import" not in response.data


def test_directory_traversal_reads_flag():
    response = make_client().get("/?view=../../flag.txt")
    assert response.status_code == 200
    assert b"CHRONOS{lfi_directory_traversal_flag_0346}" in response.data
