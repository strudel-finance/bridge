// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

import "./IAmb.sol";
import "./Forwarder.sol";
import "./IStrudel.sol";
import "./ITokenRecipient.sol";

contract StrudelMediator is ITokenRecipient {
  event StartCross(bytes32 indexed msgId,
                   address indexed sender,
                   address indexed recipient,
                   uint256 value);
  event EndCross(address indexed recipient,
                 uint256 value);
  
  IAMB public amb;

  address public admin;
  IStrudel public strudel;
  address public otherMediator;
  address public forwarder;
  uint256 public gasLimit;
  bool isMainnet;

  constructor(address _amb) {
    amb = IAMB(_amb);
    admin = msg.sender;
  }

  function set(address _strudel,
               address _otherMediator,
               address _forwarder,
               uint256 _gasLimit,
               bool _isMainnet,
               address _admin) public {
    require(msg.sender == admin, "Only admin");
    strudel = IStrudel(_strudel);
    otherMediator = _otherMediator;
    forwarder = _forwarder;
    gasLimit = _gasLimit;
    isMainnet = _isMainnet;
    admin = _admin;
  }

  function renounceMinter() public {
    require(msg.sender == admin, "Only admin");
    strudel.renounceMinter();
  }

  function startCross(uint256 _value, address _recipient) public returns (bool) {

    require(!isMainnet, "Use approveAndCall on mainnet");

    bytes4 methodSelector = StrudelMediator(address(0)).endCross.selector;
    bytes memory data = abi.encodeWithSelector(methodSelector, _value, _recipient);

    bytes4 f_methodSelector = Forwarder(address(0)).forwardToEth.selector;
    bytes memory f_data = abi.encodeWithSelector(f_methodSelector, otherMediator, data);
    
    bytes32 msgId = amb.requireToPassMessage(
        forwarder,
        f_data,
        gasLimit
    );
    
    strudel.burn(msg.sender, _value);
    
    emit StartCross(msgId, msg.sender, _recipient, _value);
    return true;
  }

  function receiveApproval(address _from,
                           uint256 _value,
                           address _token,
                           bytes calldata _extraData
                           ) external override {
    require(msg.sender == address(strudel), "Only strudel can call.");
    require(_token == address(strudel), "Only strudel can call.");
    require(isMainnet, "Use startCross on BSC");

    address _recipient = getAddr(_extraData);

    bytes4 methodSelector = StrudelMediator(address(0)).endCross.selector;
    bytes memory data = abi.encodeWithSelector(methodSelector, _value, _recipient);

    bytes4 f_methodSelector = Forwarder(address(0)).forwardToBsc.selector;
    bytes memory f_data = abi.encodeWithSelector(f_methodSelector, otherMediator, data);
    
    bytes32 msgId = amb.requireToPassMessage(
        forwarder,
        f_data,
        gasLimit
    );

    strudel.burnFrom(_from, _value);
    emit StartCross(msgId, _from, _recipient, _value);
  }

  function endCross(uint256 _value, address _recipient) public returns (bool) {
    require(msg.sender == address(amb), "Only AMB can call.");
    require(amb.messageSender() == forwarder, "Not receiving this from forwarder");

    strudel.mint(_recipient, _value);
    
    emit EndCross(_recipient, _value);
    return true;
  }

  function getAddr(bytes memory _extraData) internal pure returns (address){
    address addr;
    assembly {
      addr := mload(add(_extraData,20))
    }
    return addr;
  }
}
