<?php
class Bizum
{
    private $dbCommand;

    public function __construct($dbCommand)
    {
        $this->dbCommand = $dbCommand;
    }

    public function checkuser($ssid, $username)
    {
        try {
            // Llamar a la procedure sp_check_pwd
            $result = $this->dbCommand->execute('sp_uc_check_username', array($ssid, $username));

            // var_dump($result);
            // Obtener el resultado
            // $result = $result->fetch(PDO::FETCH_ASSOC);

            if ($result[0] == "1") {
                echo "<span style='color: green;'>✅ Usuario existente</span>";
            } elseif ($result[0] == "2") {
                echo "<span style='color: orange;'>⚠️ No te puedes enviar un bizum a ti mismo</span>";
            } else {
                echo "<span style='color: red;'>❌ Usuario no disponible</span>";
            }
        } catch (Exception $e) {
            echo "<span style='color: red;'>⚠️ Error en la validación: " . $e->getMessage() . "</span>";
        }
    }

    public function checkbalance($ssid)
    {
        try {
            $result = $this->dbCommand->execute("sp_uc_check_balance", array($ssid));

            // Establecer el encabezado para XML
            header('Content-Type: text/xml');

            // Mostrar la respuesta XML
            echo $result;
        } catch (Exception $e) {
            echo "<span style='color: red;'>⚠️ Error en la validación: " . $e->getMessage() . "</span>";
        }
    }

    public function checkLastTransaction($ssid)
    {
        try {
            $result = $this->dbCommand->execute('sp_uc_get_last_user_transaction', array($ssid));

            // Establecer el encabezado para XML
            header('Content-Type: text/xml');

            // Mostrar la respuesta XML
            echo $result;
        } catch (Exception $e) {
            echo "<span style='color: red;'>⚠️ Error en la validación: " . $e->getMessage() . "</span>";
        }
    }

    public function getTransactions($ssid) {
        try {
            $result = $this->dbCommand->execute('sp_uc_get_user_transactions', array($ssid));

            // Establecer el encabezado para XML
            header('Content-Type: text/xml');

            // Mostrar la respuesta XML
            echo $result;
        } catch (Exception $e) {
            echo "<span style='color: red;'>⚠️ Error al obtener transacciones: " . $e->getMessage() . "</span>";
        }
    }

    public function sendBizum($ssid, $reciever, $amount)
    {
        try {
            $result = $this->dbCommand->execute('sp_uc_send_bizum', array($ssid, $reciever, $amount));

            // Establecer el encabezado para XML
            header('Content-Type: text/xml');

            // Mostrar la respuesta XML
            echo $result;
        } catch (Exception $e) {
            echo "<span style='color: red;'>⚠️ Error en el envio: " . $e->getMessage() . "</span>";
        }
    }

    // public function checkAmountSender($sender,$amount,$action){
    //     $result = $this->dbCommand->execute('CheckAmount', array($sender,$amount,$this->url(),$action));

    //     return $result;
    // }

    // private function __executeTransaction($sender, $reciever, $amount,$pdoObject,$action){

    //     $myBlockchain = new Blockchain($this->dbCommand,$pdoObject);

    //     $transaction1 = new Transaction($this->dbCommand,$sender, $reciever, $amount,$this->url(),$action);

    //     $latestIndex= $myBlockchain->getLatestBlock()->index;
    //     $newBlockId = $latestIndex + 1;

    //     $block = new Block($this->dbCommand,$newBlockId, null, [$transaction1]);

    //     $myBlockchain->addBlock($block);

    //     $myBlockchain->addTransaction($transaction1,$newBlockId);

    //     if ($myBlockchain->isChainValid()) {
    //         //echo "La cadena es correcta! ";

    //         $this->__executeBizum($sender, $reciever, $amount,$action);

    //         return;
    //     } else {
    //         //echo "la cadena NO es correcta!";
    //     }

    // }

    // private function __executeBizum($sender, $reciever, $amount,$action){

    //     $result = $this->dbCommand->execute('sp_wdev_create_bizzum', array($sender,$reciever,$amount,$this->url(),$action));


    //     header('Content-Type: text/xml');
    //     echo $result;
    //     exit;

    // }

    public function viewTransaction($sender, $action)
    {

        $result = $this->dbCommand->execute('ViewUserTransactions', array($sender, $this->url(), $action));

        header('Content-Type: text/xml');
        echo $result;

    }

    public function url()
    {
        // Obtener el protocolo
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';

        // Obtener el host y la URI de la solicitud
        $host = $_SERVER['HTTP_HOST'];
        $requestUri = $_SERVER['REQUEST_URI'];

        // Concatenar todo para obtener la URL completa
        $url = $protocol . '://' . $host . $requestUri;

        return $url;
    }

    public function method()
    {
        $method = $_SERVER['REQUEST_METHOD'];
        return $method;
    }
}
?>