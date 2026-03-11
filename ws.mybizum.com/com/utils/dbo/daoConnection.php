<?php

class DBConnection
{
    private PDO $pdo;

    public function __construct(
        string $server = "host.docker.internal,1433",
        string $database = "master",
        string $user = "SA",
        string $password = "Asix1234"
    ) {
        $this->connectON($server, $database, $user, $password);
    }

    private function connectON(string $server, string $database, string $user, string $password): void
    {
        $dsn = "sqlsrv:Server=$server;Database=$database;Encrypt=true;TrustServerCertificate=true";

        try {
            $this->pdo = new PDO($dsn, $user, $password);
            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            throw new Exception("Error de conexión: " . $e->getMessage());
        }
    }

    public function getPDOObject(): PDO
    {
        return $this->pdo;
    }
}
