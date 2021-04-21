// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

import "./IAmb.sol";


contract Forwarder {
  event PassToEth(bytes32 indexed msgId, address mediator, bytes data);
  event PassToBsc(bytes32 indexed msgId, address mediator, bytes data);
  
  IAMB bscAmb;
  IAMB ethAmb;
  
  address ethMediator;
  address bscMediator;
  uint256 gasLimit;

  bool isFrozen;
  
  constructor(address _bscAmb, address _ethAmb) {
    bscAmb = IAMB(_bscAmb);
    ethAmb = IAMB(_ethAmb);
  }

  function set(address _ethMediator,
               address _bscMediator,
               uint256 _gasLimit) public {
    require(!isFrozen, "Contract is frozen");
    ethMediator = _ethMediator;
    bscMediator = _bscMediator;
    gasLimit = _gasLimit;
  }

  function freeze() public {
    isFrozen = true;
  }

  function forwardToEth(address _mediator, bytes calldata _data) public {
    require(msg.sender == address(bscAmb), "Only AMB can call.");
    require(bscAmb.messageSender() == bscMediator, "Not receiving this from BSC Mediator.");
    bytes32 msgId = ethAmb.requireToPassMessage(
        _mediator,
        _data,
        gasLimit
    );
    
    emit PassToEth(msgId, _mediator, _data);
  }

  function forwardToBsc(address _mediator, bytes calldata _data) public {
    require(msg.sender == address(ethAmb), "Only AMB can call.");
    require(ethAmb.messageSender() == ethMediator, "Not receiving this from ETH Mediator.");
    bytes32 msgId = bscAmb.requireToPassMessage(
        _mediator,
        _data,
        gasLimit
    );

    emit PassToBsc(msgId, _mediator, _data);
  }
}
