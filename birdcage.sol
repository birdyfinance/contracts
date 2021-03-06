// SPDX-License-Identifier: MIT
// Based off yeild yak timelock, because of the simplicity <3


pragma solidity ^0.6.12;

import "./MasterChef.sol";



contract BirdCage {
    // constants
    uint256 public PROPOSED_ADD_POOL_allocPoint;
    IERC20 public PROPOSED_ADD_POOL_lpToken; // needs import
    uint16 public PROPOSED_ADD_POOL_withdrawFee;
    uint256 public PROPOSED_SET_POOL_pid;
    uint256 public PROPOSED_SET_POOL_allocPoint;
    uint16 public PROPOSED_SET_POOL_withdrawFee;
    uint256 public PROPOSED_EMISSION;
    uint256 public PROPOSED_MINT_AMOUNT;
    address public PROPOSED_MINT_TO;
    address public PROPOSED_MINTER;
    
    //---------------------------------------------------------------

    uint public constant TIME_BEFORE_SET_POOL_EXECUTION = 12 hours;
    uint public constant TIME_BEFORE_ADD_POOL_EXECUTION = 12 hours;
    uint public constant TIME_BEFORE_EMISSION_CHANGE = 12 hours;
    uint public constant TIME_BEFORE_MINT_TOKEN = 12 hours;
    
    uint public constant TIME_BEFORE_OWNERSHIP_TRANSFER = 24 hours;
    uint public constant TIME_BEFORE_MINTER_ROLE_TRANSFER = 24 hours;
    //---------------------------------------------------------------
    address public manager;
    MasterChefV2 public CHEF;
    BirdToken public BIRD;
    address public pendingOwner;
    enum Functions { transferOwnership, emergencyWithdraw, add, set, updateEmissionRate, mintToken, transferMinter }
    mapping(Functions => uint) public timelock;

    constructor(address _CHEF, address _birdToken) public {
        manager = msg.sender;
        CHEF = MasterChefV2(_CHEF);
        BIRD = BirdToken(_birdToken);
    }

    // modifiers
    modifier onlyManager {require(msg.sender == manager);_;}
    modifier setTimelock(Functions _fn, uint timelockLength) {timelock[_fn] = block.timestamp + timelockLength;_;}
    modifier enforceTimelock(Functions _fn) {require(timelock[_fn] != 0 && timelock[_fn] <= block.timestamp, "Yak Based Timelock::enforceTimelock");_;timelock[_fn] = 0;}
    

    // transferOwnership functionality
    function proposeOwner(address _pendingOwner) external onlyManager setTimelock(Functions.transferOwnership, TIME_BEFORE_OWNERSHIP_TRANSFER) {
        pendingOwner = _pendingOwner;}
    
    function executeSetNewOwner() external enforceTimelock(Functions.transferOwnership) {
        CHEF.transferOwnership(pendingOwner);
        pendingOwner = address(0);}// whats this mean?
    

    function proposeAddPool(uint256 _allocPoint, IERC20 _lpToken, uint16 _withdrawFeeBP) external onlyManager setTimelock(Functions.add, TIME_BEFORE_ADD_POOL_EXECUTION) {
        PROPOSED_ADD_POOL_allocPoint = _allocPoint;
        PROPOSED_ADD_POOL_lpToken = _lpToken;
        PROPOSED_ADD_POOL_withdrawFee =  _withdrawFeeBP;
    }
    
    
    function executeAddPool() external enforceTimelock(Functions.add) {
        CHEF.add(PROPOSED_ADD_POOL_allocPoint, PROPOSED_ADD_POOL_lpToken, PROPOSED_ADD_POOL_withdrawFee, false);
        CHEF.massUpdatePools();
    }

    function proposeSetPool(uint256 _pid, uint256 _allocPoint, uint16 _withdrawFeeBP) external onlyManager setTimelock(Functions.set, TIME_BEFORE_SET_POOL_EXECUTION) {
        PROPOSED_SET_POOL_allocPoint = _allocPoint;
        PROPOSED_SET_POOL_withdrawFee = _withdrawFeeBP;
        PROPOSED_SET_POOL_pid = _pid;
    }
    
    function executeSetPool() external enforceTimelock(Functions.set) {
        CHEF.set(PROPOSED_SET_POOL_pid, PROPOSED_SET_POOL_allocPoint, PROPOSED_SET_POOL_withdrawFee, false);
        CHEF.massUpdatePools();
    }
    
    function proposeEmission(uint256 _emission) external onlyManager setTimelock(Functions.updateEmissionRate, TIME_BEFORE_EMISSION_CHANGE) {
        PROPOSED_EMISSION = _emission;
    }
    
    function executeEmission() external enforceTimelock(Functions.updateEmissionRate) {
        CHEF.updateEmissionRate(PROPOSED_EMISSION);
    }
    
    function proposeMintToken(address _to, uint256 _amount) external onlyManager setTimelock(Functions.mintToken, TIME_BEFORE_MINT_TOKEN) {
        PROPOSED_MINT_AMOUNT = _amount;
        PROPOSED_MINT_TO = _to;
    }
    
    function executeMintToken() external enforceTimelock(Functions.mintToken) {
        BIRD.mint(PROPOSED_MINT_TO, PROPOSED_MINT_AMOUNT);
    }
    
    function proposeNewMinter(address newMinter) external onlyManager setTimelock(Functions.transferMinter, TIME_BEFORE_MINTER_ROLE_TRANSFER) {
        PROPOSED_MINTER = newMinter;
    }
    
    function executeNewMinter() external enforceTimelock(Functions.transferMinter) {
        BIRD.setMinter(PROPOSED_MINTER);
    }
}
