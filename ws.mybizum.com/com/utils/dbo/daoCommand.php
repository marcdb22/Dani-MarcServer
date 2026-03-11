<?php
class DBCommand
{
    private $pdo;
    private $xml;

    public function __construct($pdo)
    {
        $this->pdo = $pdo;
    }

    public function execute_simple($sql, $params = array())
    {
        $request = $this->pdo->prepare($sql);

        foreach ($params as $index => $value) {
            $request->bindValue($index + 1, $value);
        }

        $request->execute();
        $datos = $request->fetchAll(PDO::FETCH_ASSOC);

        $xml = '<?xml version="1.0" encoding="UTF-8"?><Response>';

        if (empty($datos)) {
            $xml .= '<Message>No data found</Message>';
        } else {
            foreach ($datos as $row) {
                $xml .= '<User>';
                foreach ($row as $key => $value) {
                    $xml .= '<' . $key . '>' . htmlspecialchars($value) . '</' . $key . '>';
                }
                $xml .= '</User>';
            }
        }

        $xml .= '</Response>';
        $this->xml = $xml;
    }

    public function execute($procedureName, $params = array())
    {
        $placeholders = empty($params)
            ? ''
            : implode(',', array_fill(0, count($params), '?'));

        // SQL Server necesita EXEC NombreProc ?, ?, ?
        $sql = "EXEC $procedureName $placeholders";

        $this->execute_simple($sql, $params);
    }

    public function getResult()
    {
        return $this->xml;
    }
}
?>