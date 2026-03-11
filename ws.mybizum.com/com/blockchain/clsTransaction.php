<?php

class Transaction {
    private $sender;
    private $receiver;
    private $amount;

    public function __construct($sender, $receiver, $amount) {
        $this->sender = $sender;
        $this->receiver = $receiver;
        $this->amount = $amount;
    }

    public function getData() {
        return [$this->sender, $this->receiver, $this->amount];
    }

    public function save($index) {
        global $dbCommand;
        $dbCommand->execute('AddTransaction', array($this->sender, $this->receiver, $this->amount, $index));
    }
}