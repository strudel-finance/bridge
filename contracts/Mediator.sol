// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

import "./IAmb.sol";
import "./Forwarder.sol";
import "./IERC20.sol";
import "./ITokenRecipient.sol";

contract Mediator is ITokenRecipient {
  event StartCross(bytes32 indexed msgId,
                   bool isTrdl,
                   address indexed sender,
                   address indexed recipient,
                   uint256 value);
  event EndCross(bool isTrdl,
                 address indexed recipient,
                 uint256 value);
  
  IAMB public amb;
  
  IERC20 public strudel;
  IERC20 public vbch;
  address public otherMediator;
  address public forwarder;
  uint256 public gasLimit;
  bool isMainnet;

  bool isFrozen;

  constructor(address _amb) {
    amb = IAMB(_amb);
  }

  function set(address _strudel,
               address _vbch,
               address _otherMediator,
               address _forwarder,
               uint256 _gasLimit,
               bool _isMainnet) public {
    require(!isFrozen, "Contract is frozen");
    strudel = IERC20(_strudel);
    vbch = IERC20(_vbch);
    otherMediator = _otherMediator;
    forwarder = _forwarder;
    gasLimit = _gasLimit;
    isMainnet = _isMainnet;
  }

  function freeze() public {
    isFrozen = true;
  }

  function startCross(bool isTrdl, uint256 _value, address _recipient) public returns (bool) {

    bytes4 methodSelector = Mediator(address(0)).endCross.selector;
    bytes memory data = abi.encodeWithSelector(methodSelector, isTrdl, _value, _recipient);

    bytes4 f_methodSelector;
    if (isMainnet) {
      f_methodSelector = Forwarder(address(0)).forwardToBsc.selector;
    } else {
      f_methodSelector = Forwarder(address(0)).forwardToEth.selector;
    }
    bytes memory f_data = abi.encodeWithSelector(f_methodSelector, otherMediator, data);
    
    bytes32 msgId = amb.requireToPassMessage(
        forwarder,
        f_data,
        gasLimit
    );

    if (isTrdl) {
      strudel.burn(msg.sender, _value);
    } else {
      vbch.burn(msg.sender, _value);
    }
    
    emit StartCross(msgId, isTrdl, msg.sender, _recipient, _value);
    return true;
  }

  // for strudel: only called on mainnet
  function receiveApproval(address _from,
                           uint256 _value,
                           address _token,
                           bytes calldata _extraData
                           ) external override {
    require(msg.sender == address(strudel), "Only strudel can call.");
    require(_token == address(strudel), "Only strudel can call.");

    address _recipient = getAddr(_extraData);

    bytes4 methodSelector = Mediator(address(0)).endCross.selector;
    bytes memory data = abi.encodeWithSelector(methodSelector, true, _value, _recipient);

    bytes4 f_methodSelector = Forwarder(address(0)).forwardToBsc.selector;
    bytes memory f_data = abi.encodeWithSelector(f_methodSelector, otherMediator, data);
    
    bytes32 msgId = amb.requireToPassMessage(
        forwarder,
        f_data,
        gasLimit
    );

    strudel.burnFrom(_from, _value);
    emit StartCross(msgId, true, _from, _recipient, _value);
  }

  function endCross(bool isTrdl, uint256 _value, address _recipient) public returns (bool) {
    require(msg.sender == address(amb), "Only AMB can call.");
    require(amb.messageSender() == forwarder, "Not receiving this from forwarder");

    if (isTrdl) {
      strudel.mint(_recipient, _value);
    } else {
      vbch.mint(_recipient, _value);
    }
    
    emit EndCross(isTrdl, _recipient, _value);
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
