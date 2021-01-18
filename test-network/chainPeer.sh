#!/bin/bash

#set -euo pipefail
# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  chainPeer.sh <Mode> [args]"
  echo "    <Mode>"
  echo "      - 'start'    - 启动区块链网络"
  echo "      - 'status'   - 查看区块链网络状态和当前环境所属组织"
  #echo "      - 'init'     - 初始化分类帐本（账本是10个汽车信息）"
  echo "      - 'down'     - 关闭区块链网络"
  echo "      - 'queryCar' - 查询汽车信息，需要参数如下："
  echo "          -num <CAR0 ~ CAR10>    - 汽车编号"
  echo "      - 'queryAllCars' - 查询所有汽车信息"
  echo "      - 'createCar'   - 创建一个汽车信息，需要参数如下："
  echo "          -num <string>      - 汽车编号"
  echo "          -make <string>     - 制造商"
  echo "          -model <string>    - 型号"
  echo "          -colour <string>   - 颜色"
  echo "          -owner <string>    - 所属者"
  echo "      - 'ChangeCarOwner'   - 修改汽车所属者，需要参数如下："
  echo "          -num <string>      - 汽车编号"
  echo "          -owner <string>    - 所属者"
  echo
  echo " Examples:"
  echo "  chainPeer.sh start"
  echo "  chainPeer.sh status"
  #echo "  chainPeer.sh init"
  echo "  chainPeer.sh down"
  echo "  chainPeer.sh queryCar -num CAR8"
  echo "  chainPeer.sh queryAllCars"
  echo "  chainPeer.sh createCar -num CAR111 -make BYD -model S6 -colour red -owner bruce"
  echo "  chainPeer.sh ChangeCarOwner -num CAR111 -owner bruce11111111"

}

function restart() {
  echo "开始启动区块链网络。。。"
  ${PWD}/network.sh down && ${PWD}/network.sh up && ${PWD}/network.sh createChannel && ${PWD}/network.sh deployCC
  if [[ $? -ne 0 ]]; then
    echo "启动失败！"
  else

    echo "启动成功！"
  fi
}

function status() {
  ps_data=$(docker ps)
  echo $ps_data | grep "orderer.example.com" >/dev/null 2>&1
  re1=$?
  echo $ps_data | grep "peer0.org2.example.com" >/dev/null 2>&1
  re2=$?
  echo $ps_data | grep "peer0.org1.example.com" >/dev/null 2>&1
  re3=$?
  echo $ps_data | grep "dev-peer0.org2.example.com-" >/dev/null 2>&1
  re4=$?
  echo $ps_data | grep "dev-peer0.org1.example.com-" >/dev/null 2>&1
  re5=$?

  if [[ $re1 -ne 0 ]] || [[ $re2 -ne 0 ]] || [[ $re3 -ne 0 ]] || [[ $re4 -ne 0 ]] || [[ $re5 -ne 0 ]]; then
    echo "status: failed"
  else
    echo "status: alive"
  fi
}

function down() {
  ${PWD}/network.sh down
  if [[ $? -ne 0 ]]; then
    echo "停止失败！"
  else
    echo "停止成功！"
  fi
}

function exports() {
  export PATH=${PWD}/../bin:${PWD}:$PATH
  export FABRIC_CFG_PATH=$PWD/../config/
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

function queryCar() {
  exports
  peer chaincode query -C mychannel -n fabcar -c '{"Args":["queryCar", "'$1'"]}'
}

function queryAllCars() {
  exports
  peer chaincode query -C mychannel -n fabcar -c '{"Args":["queryAllCars"]}'
}

function createCar() {
  exports
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile \
    ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C mychannel -n fabcar --peerAddresses localhost:7051 --tlsRootCertFiles \
    ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses \
    localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -c '{"function":"CreateCar","Args":["'$1'","'$2'","'$3'","'$4'","'$5'"]}'
}

function ChangeCarOwner() {
  exports
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile \
    ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C mychannel -n fabcar --peerAddresses localhost:7051 --tlsRootCertFiles \
    ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses \
    localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -c '{"function":"ChangeCarOwner","Args":["'$1'","'$2'"]}'
}

function parseParam() {
  while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
    -h)
      printHelp
      exit 0
      ;;
    -num)
      num=$2
      shift
      ;;
    -make)
      make=$2
      shift
      ;;
    -model)
      model=$2
      shift
      ;;
    -colour)
      colour=$2
      shift
      ;;
    -owner)
      owner=$2
      shift
      ;;
    *)
      echo
      echo "Unknown flag: $key"
      echo
      printHelp
      exit 1
      ;;
    esac
    shift
  done

}

## Parse mode
if [[ $# -lt 1 ]]; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

if [ "$MODE" == "start" ]; then
  restart
  echo
elif [ "$MODE" == "status" ]; then
  status
  echo
elif [ "$MODE" == "down" ]; then
  down
  echo
elif [ "$MODE" == "queryCar" ]; then
  parseParam $*
  queryCar $num
  echo
elif [ "$MODE" == "queryAllCars" ]; then
  queryAllCars
  echo
elif [ "$MODE" == "createCar" ]; then
  parseParam $*
  createCar $num $make $model $colour $owner
  echo
elif [ "$MODE" == "ChangeCarOwner" ]; then
  parseParam $*
  ChangeCarOwner $num $owner
  echo
fi
