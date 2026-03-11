<?php

class Block
{
    public $index;
    public $timestamp;
    private $transactions = [];
    public $previousHash;
    public $hash;

    public function __construct($index, $timestamp, $transactions, $previousHash = '', $hash = '')
    {
        $this->index = $index;
        $this->timestamp = $timestamp;
        $this->transactions = $transactions;
        $this->previousHash = $previousHash;
        if ($hash != '') {
            $this->hash = $hash;
        } else {
            $this->hash = $this->calculateHash();
        }
    }

    public function calculateHash()
    {
        return hash("MD5", $this->index . $this->timestamp . json_encode($this->transactions)
            . $this->previousHash, false);
    }

    // public function getTransactions()
    // {
    //     return $this->transactions;
    // }

    public function save()
    {
        global $dbCommand;
        $dbCommand->execute('AddBlock', array($this->previousHash, $this->hash));
        for ($i = 0; $i < count($this->transactions); $i++) {
            $actual = $this->transactions[$i];
            $actual->save($this->index);
        }
    }

    // public function load() {

    // }
}