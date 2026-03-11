<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

ob_clean();
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'utils/dbo/daoConnection.php';
require_once 'utils/dbo/daoCommand.php';
require_once 'utils/mailtools/mail_sender.php';
require_once 'security/clsUserManager.php';
require_once 'utils/dbo/daoManager.php';
// require_once 'blockchain/clsBlock.php';
// require_once 'blockchain/clsBlockchain.php';
require_once 'blockchain/clsTransaction.php';
require_once 'bizum/clsBizum.php';

// Crear una instancia de DBCommand
function newDBCommand($server, $db, $user, $password)
{
    $connection = new DBConnection($server, $db, $user, $password);
    $pdoObject = $connection->getPDOObject();
    return new DBCommand($pdoObject);

}
function connUser()
{
    $dbCommand = newDBCommand('172.17.0.2,1433', 'PP_DDBB', 'sa', 'Password2!');
    return new UserManager($dbCommand);
}

function connDBManager()
{
    $dbCommand = newDBCommand('172.17.0.2,1433', 'PP_DDBB', 'sa', 'Password2!');
    return new DBManager($dbCommand);
}

function connBizum()
{
    $dbCommand = newDBCommand('172.17.0.2,1433', 'PP_DDBB', 'sa', 'Password2!');
    return new Bizum($dbCommand);
}
// function connBlockChain()
// {
//     $connection = new DBConnection('172.17.0.2,1433', 'BlockchainDB', 'sa', 'Password2!');
//     $pdoObject = $connection->getPDOObject();
//     $dbCommand = new DBCommand($pdoObject);
//     return $dbCommand;
// }

$action = isset($_GET['action']) ? $_GET['action'] : '';

if (empty($action)) {
    echo "Accion no especificada.";
} else {
    switch ($action) {
        // case "register": // AÑADIR PARAMETROS FALTANTES

        //     $userManager->register($_GET['username'], $_GET['name'], $_GET['lastname'], $_GET['password'], $_GET['email'], strtoupper($_GET['gender']), strtoupper($_GET['def_lang']));
        //     break;
        case "register":
            $username = $_GET['username'];
            $name = $_GET['name'];
            $lastname = $_GET['lastname'];
            $password = $_GET['password'];
            $email = $_GET['email'];
            $gender = strtoupper($_GET['gender']);
            $def_lang = strtoupper($_GET['def_lang']);
            $userManager = connUser();
            $userManager->register($username, $name, $lastname, $password, $email, $gender, $def_lang);
            break;
        case "login":
            $userManager = connUser();
            $userManager->login($_GET['username'], hash('MD5', $_GET['password']));
            break;
        case "logout":
            $userManager = connUser();
            $userManager->logout($_GET['ssid']);
            break;
        case "recoverypassEmail":
            $userManager = connUser();
            $userManager->recoverPasswordEmail($_GET['email']);
            break;
        case "recoverypassPIN":
            $userManager = connUser();
            $userManager->recoverPasswordPIN($_GET['email'], $_GET['pin'], $_GET['password']);
            break;
        case "changepass":
            $userManager = connUser();
            $userManager->changePassword($_GET['ssid'], hash('MD5', $_GET['password']), $_GET['newpassword']);
            break;
        case "viewcon":
            $dbManager = connDBManager();
            $dbManager->viewConnections();
            break;
        case "viewconhist":
            $dbManager = connDBManager();
            $dbManager->viewHistoricConnections();
            break;
        case "accvalidate":
            $userManager = connUser();
            $userManager->accountValidate($_GET['username'], $_GET['code']);
            break;
        case "listusers":
            $userManager = connUser();
            $userManager->listusers($_GET['ssid']);
            break;
        case "checkpwd":
            $userManager = connUser();
            $userManager->checkpwd($_GET['pwd']);
            break;
        case "checkuser":
            $bizum = connBizum();
            $bizum->checkuser($_GET['ssid'], $_GET['username']);
            break;
        case "checkbalance":
            $bizum = connBizum();
            $bizum->checkbalance($_GET['ssid']);
            break;
        case "checklasttransaction":
            $bizum = connBizum();
            $bizum->checkLastTransaction($_GET['ssid']);
            break;
        case "getTransactions":
            $bizum = connBizum();
            $bizum->getTransactions($_GET['ssid']);
            break;
        case "addTransaction":
            $bizum = connBizum();
            $bizum->sendBizum($_GET['ssid'], $_GET['receiver'], $_GET['amount']);

            // $dbCommand = newDBCommand('172.17.0.2,1433', 'BlockchainDB', 'sa', 'Password2!');
            // $myBlockchain = new Blockchain();
            // $tx = new Transaction($_GET['sender'], $_GET['receiver'], $_GET['amount']);
            // $block2 = new Block(($myBlockchain->getLatestBlock())->index + 1, date("Y-m-d H:i:s"), [$tx]);
            // $myBlockchain->addBlock($block2);
            // $myBlockchain->save();
            break;
        default:
            echo "Acción no válida.";
            break;
    }
}

// Register (POR EL MOMENTO BIEN):
// http://localhost:40080/APP%20Login/Front-end/index.php?action=register&username=polrabascall&name=Pol&lastname=Rabascall&password=Test12345!!&email=polrabascall@gmail.com
// http://localhost:40022/gen-web/PHP/index.php?action=register&username=PauAllendee&name=Pau&lastname=Allende&password=C0ntraseña2004!!&email=pauallendeherraiz@gmail.com

// Register2 (POR EL MOMENTO BIEN):
// http://localhost:40080/APP%20Login/Front-end/index.php?action=register2&username=polrabascall&name=Pol&lastname=Rabascall&password=Test12345!!&email=polrabascall@gmail.com&gender=m&def_lang=esp
// http://localhost:40022/gen-web/PHP/index.php?action=register&username=PauAllendee&name=Pau&lastname=Allende&password=C0ntraseña2004!!&email=pauallendeherraiz@gmail.com

// Account Validate (CORRECTO):
// http://http://localhost:40080/APP%20Login/Front-end/index.php?action=accvalidate&username=polrabascall&code=65897
// http://localhost:40022/gen-web/PHP/index.php?action=accvalidate&username=PauAllendee&code=40381

// Login (FECHA MAL+): 
// http://localhost:40080/APP%20Login/Front-end/index.php?action=login&username=polrabascall&password=Test12345!!
// http://localhost:40022/gen-web/PHP/index.php?action=login&username=PauAllendee&password=C0ntraseña2004!!

// Logout (FECHA MAL+): 
// http://localhost:40080/APP%20Login/Front-end/index.php?action=logout
// http://localhost:40022/gen-web/PHP/index.php?action=logout

// Change Password (BIEN?):
// http://localhost:40080/APP%20Login/Front-end/index.php?action=changepass&username=polrabascall&password=Test12345!!&newpassword=NewPassword12345!!
// http://localhost:40022/gen-web/PHP/index.php?action=changepass&username=PauAllendee&password=C0ntraseña2004!!&newpassword=NewPassword12345!!

// View Active Connections: 
// http://localhost:40080/APP%20Login/Front-end/index.php?action=viewcon
// http://localhost:40022/gen-web/PHP/index.php?action=viewcon

// View Historical Connections: 
// http://localhost:40080/APP%20Login/Front-end/index.php?action=viewconhist
// http://localhost:40022/gen-web/PHP/index.php?action=viewconhist


//http://localhost:40080/APP%20Login/Front-end/index.php?action=listusers&ssid=a0b39afe-6971-4d0c-85ca-d63bb5d07de2

?>