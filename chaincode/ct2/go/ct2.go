package main

import (
	"errors"
	"fmt"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type Ct2 struct {
	contractapi.Contract
}

func (c *Ct2) InitCt2(ctx contractapi.TransactionContextInterface) error {
	return ctx.GetStub().PutState("exampleKey", []byte("exampleValue"))
}

func (c *Ct2) GetCt2(ctx contractapi.TransactionContextInterface, key string) (string, error) {

	stateByes, err := ctx.GetStub().GetState(key)

	if err != nil {
		return "", fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if stateByes == nil {
		return "", fmt.Errorf("%s does not exist", key)
	}
	return string(stateByes), nil
}

func (c *Ct2) SetCt2(ctx contractapi.TransactionContextInterface, key string, value string) error {
	//err := ctx.GetStub().PutState("CAR"+strconv.Itoa(i), carAsBytes)
	if key == "" || value == ""{
		return errors.New("key or value is empty")
	}
	return ctx.GetStub().PutState(key, []byte(value))
}

func main() {
	chaincode, err := contractapi.NewChaincode(new(Ct2))

	if err != nil {
		fmt.Printf("Error create ct2 chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting ct2 chaincode: %s", err.Error())
	}
}



