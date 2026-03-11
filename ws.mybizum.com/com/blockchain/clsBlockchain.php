<?php

class Blockchain
{
    public $chain;

    public function __construct()
    {
        $this->chain = [];
        $this->load();
        // $this->chain = [$this->createGenesisBlock()];
    }

    private function createGenesisBlock()
    {
        return new Block(0, date("Y-m-d H:i:s"), [], '0');
    }

    public function getLatestBlock()
    {
        return $this->chain[count($this->chain) - 1];
    }

    public function addBlock($newBlock)
    {
        $newBlock->previousHash = $this->getLatestBlock()->hash;
        // echo "<br> <br>". $newBlock->previousHash;
        $newBlock->hash = $newBlock->calculateHash();
        array_push($this->chain, $newBlock);
    }

    public function isChainValid()
    {
        for ($i = 1; $i < count($this->chain); $i++) {
            $currentBlock = $this->chain[$i];
            $previousBlock = $this->chain[$i - 1];

            if ($currentBlock->hash !== $currentBlock->calculateHash()) {
                return false;
            }

            if ($currentBlock->previousHash !== $previousBlock->hash) {
                return false;
            }

        }
        return true;
    }

    // public function add_SQL($dbManager)
    // {
    //     for ($i = 0; $i < count($this->chain); $i++) {
    //         $currentBlock = $this->chain[$i];
    //         $dbManager->add_blockSQL($currentBlock);
    //     }
    // }

    public function save()
    {
        global $dbCommand;
        for ($i = 0; $i < count($this->chain); $i++) {
            $currentBlock = $this->chain[$i];
            $blockchain = $dbCommand->execute('BlockExists', array($currentBlock->index));
            if ($blockchain == 0) {
                $currentBlock->save();
            }
        }
    }

    public function load()
    {
        global $dbCommand;
        $blockchain = $dbCommand->execute('GetBlockChainXML', array());
        if (empty($blockchain) || $blockchain == '' || $blockchain == null) {
            array_push($this->chain, $this->createGenesisBlock());
        } else {
            $xml = simplexml_load_string($blockchain);

            foreach ($xml->xpath("//Block") as $block) {
                $index = (int) $block->BlockID;
                $timestamp = $block->Timestamp;
                $previousHash = (string) $block->PreviousHash;
                $hash = (string) $block->Hash;
                $transactions = [];

                foreach ($block->xpath("Transaction") as $transaction) {
                    $sender = (string) $transaction->Sender;
                    $receiver = (string) $transaction->Receiver;
                    $amount = (float) $transaction->Amount;
                    $transact = new Transaction($sender, $receiver, $amount);
                    array_push($transactions, $transact);
                }

                $newBlock = new Block($index, $timestamp, $transactions, $previousHash, $hash);
                array_push($this->chain, $newBlock);
            }
        }
    }
}