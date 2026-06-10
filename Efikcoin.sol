// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * EFIKCOIN (EFC) - Life Empowerment Contract
 * Contains: Trading, Airdrop, Staking, Fees, Logo
 * Built for global community and future generations
 */

contract EFIKCOIN {
    string public name = "EFIKCOIN";
    string public symbol = "EFC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000_000 * 10**18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;
    address public treasuryWallet = 0x676cCf34C191a9D6EFE4B265b84877C619A559d0;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public buyFee = 2;
    uint256 public sellFee = 2;
    uint256 public maxWallet = 20_000_000 * 10**18;
    bool public tradingOpen;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isMaxExempt;
    mapping(address => bool) public isPair;

    // Staking storage
    mapping(address => uint256) public staked;
    mapping(address => uint256) public stakeStart;
    uint256 public totalStaked;
    uint256 public constant APY = 8;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event AirdropCompleted(uint256 recipients);

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    constructor() {
        owner = msg.sender;
        _balances[owner] = totalSupply;
        isFeeExempt[owner] = true;
        isFeeExempt[treasuryWallet] = true;
        isFeeExempt[address(this)] = true;
        isMaxExempt[owner] = true;
        isMaxExempt[treasuryWallet] = true;
        isMaxExempt[address(this)] = true;
        isMaxExempt[DEAD] = true;
        emit Transfer(address(0), owner, totalSupply);
    }

    // === ERC20 ===
    function balanceOf(address a) external view returns (uint256) { return _balances[a]; }
    function allowance(address o, address s) external view returns (uint256) { return _allowances[o][s]; }
    function approve(address s, uint256 a) external returns (bool) { _allowances[msg.sender][s] = a; emit Approval(msg.sender, s, a); return true; }
    function transfer(address to, uint256 a) external returns (bool) { _transfer(msg.sender, to, a); return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) { require(_allowances[f][msg.sender] >= a); _allowances[f][msg.sender] -= a; _transfer(f, t, a); return true; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from!= address(0) && to!= address(0));
        require(_balances[from] >= amount);
        if (!tradingOpen) require(isFeeExempt[from] || isFeeExempt[to], "Trading closed");
        if (!isMaxExempt[to] &&!isPair[to] && to!= address(this)) require(_balances[to] + amount <= maxWallet, "Max wallet");
        uint256 fee = 0;
        if (!isFeeExempt[from] &&!isFeeExempt[to]) {
            if (isPair[from]) fee = amount * buyFee / 100;
            else if (isPair[to]) fee = amount * sellFee / 100;
        }
        _balances[from] -= amount;
        if (fee > 0) { _balances[treasuryWallet] += fee; emit Transfer(from, treasuryWallet, fee); }
        _balances[to] += amount - fee;
        emit Transfer(from, to, amount - fee);
    }

    // === TRADING ===
    function openTrading() external onlyOwner { tradingOpen = true; }
    function setPair(address pair, bool status) external onlyOwner { isPair[pair] = status; }
    function setFeeExempt(address a, bool e) external onlyOwner { isFeeExempt[a] = e; }
    function setMaxExempt(address a, bool e) external onlyOwner { isMaxExempt[a] = e; }

    // === AIRDROP - build community ===
    function airdrop(address[] calldata recipients, uint256 amountEach) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner, recipients[i], amountEach);
        }
        emit AirdropCompleted(recipients.length);
    }

    function airdropVaried(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner, recipients[i], amounts[i]);
        }
        emit AirdropCompleted(recipients.length);
    }

    // === STAKING - deposit, withdraw, claim ===
    function deposit(uint256 amount) external {
        require(amount > 0);
        _transfer(msg.sender, address(this), amount);
        uint256 pending = pendingReward(msg.sender);
        if (pending > 0 && _balances[address(this)] >= pending) {
            _balances[address(this)] -= pending;
            _balances[msg.sender] += pending;
            emit Transfer(address(this), msg.sender, pending);
            emit RewardsClaimed(msg.sender, pending);
        }
        staked[msg.sender] += amount;
        stakeStart[msg.sender] = block.timestamp;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(staked[msg.sender] >= amount);
        uint256 reward = pendingReward(msg.sender);
        staked[msg.sender] -= amount;
        totalStaked -= amount;
        stakeStart[msg.sender] = block.timestamp;
        _balances[address(this)] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
        if (reward > 0 && _balances[address(this)] >= reward) {
            _balances[address(this)] -= reward;
            _balances[msg.sender] += reward;
            emit Transfer(address(this), msg.sender, reward);
            emit RewardsClaimed(msg.sender, reward);
        }
    }

    function claimRewards() external {
        uint256 reward = pendingReward(msg.sender);
        require(reward > 0);
        require(_balances[address(this)] >= reward);
        stakeStart[msg.sender] = block.timestamp;
        _balances[address(this)] -= reward;
        _balances[msg.sender] += reward;
        emit Transfer(address(this), msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    function pendingReward(address user) public view returns (uint256) {
        if (staked[user] == 0) return 0;
        uint256 timeStaked = block.timestamp - stakeStart[user];
        return staked[user] * APY * timeStaked / 100 / 365 days;
    }

    function fundStaking(uint256 amount) external onlyOwner {
        _transfer(owner, address(this), amount);
    }

    // === LOGO & GLOBAL VISIBILITY ===
    function tokenURI() external pure returns (string memory) {
        return "ipfs://bafybeihrzyodihyp5met2hs32ppj37qlowuxarvs2lnlrgujgrlwxc7fwe";
    }

    function burn(uint256 amount) external {
        _balances[msg.sender] -= amount;
        _balances[DEAD] += amount;
        emit Transfer(msg.sender, DEAD, amount);
    }

    function renounceOwnership() external onlyOwner { owner = address(0); }

    receive() external payable {}
}
