// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TribeProject is Ownable {
    struct WhitelistInput {
        uint256 tier;
        uint256 maxPurchasableTiers;
        address wallet;
    }

    struct Whitelist {
        uint256 maxPurchasableTiers;
        uint256 tiersPurchased;
        uint256 tier;
        address wallet;
        bool whitelist;
    }

    // Whitelist map
    mapping(address => Whitelist) private whitelist;

    // Private
    IERC20 private _token;
    uint256[] private tiers;
    // Public
    uint256 public startTime;
    uint256 public totalRaise;
    uint256 public totalParticipant;
    bool public isFinished;
    bool public tiersAdded;

    // Events
    event ESetAcceptedTokenAddress(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    );
    event ESetTokenAddress(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    );
    event EOpenSale(uint256 _startTime, bool _isStart);
    event EBuyTokens(
        address _sender,
        uint256 _value,
        uint256 _totalRaise,
        uint256 _totalParticipant
    );
    event EFinishSale(bool _isFinished);
    event EAddTiers(uint256[] _tiers);
    event EAddWhiteList(WhitelistInput[] _addresses);
    event ERemoveWhiteList(address[] _addresses);
    event EWithdrawBNBBalance(address _sender, uint256 _balance);

    // Read: Get token address
    function getTokenAddress() public view returns (address tokenAddress) {
        return address(_token);
    }

    // Read: Get Tier Amount in BNB
    function getTierAmount(uint256 index) public view returns (uint256 _tier) {
        if (index > 0 && index <= tiers.length) {
            return tiers[index - 1];
        }
        return 0;
    }

    function isInitialized() public view returns (bool) {
        return startTime != 0;
    }

    // Read: Is Sale Start
    function isStart() public view returns (bool) {
        return isInitialized() && startTime > 0 && block.timestamp >= startTime;
    }

    // Read: Get max payable amount against whitelisted address
    function getMaxPayableAmount(address _address)
        public
        view
        returns (uint256)
    {
        Whitelist memory whitelistWallet = whitelist[_address];
        return
            whitelistWallet.maxPurchasableTiers *
            tiers[whitelistWallet.tier - 1];
    }

    // Read: Get whitelist wallet
    function getWhitelist(address _address)
        public
        view
        returns (
            address _wallet,
            uint256 _tier,
            uint256 _tiersPurchased,
            uint256 _maxPurchasableTiers,
            bool _whitelist
        )
    {
        Whitelist memory whitelistWallet = whitelist[_address];
        return (
            _address,
            whitelistWallet.tier,
            whitelistWallet.tiersPurchased,
            whitelistWallet.maxPurchasableTiers,
            whitelistWallet.whitelist
        );
    }

    // Fallback: Revert receive ether
    fallback() external {
        revert();
    }

    // Write: Token Address
    function setTokenAddress(IERC20 token) external onlyOwner {
        require(startTime == 0, "This step should perform before the sale");

        _token = token;
        // Emit event
        emit ESetTokenAddress(
            token.name(),
            token.symbol(),
            token.decimals(),
            token.totalSupply()
        );
    }

    // Write: Open sale
    // Ex _startTime = 1618835669
    function openSale(uint256 _startTime) external onlyOwner {
        require(!isInitialized(), "This step should perform before the sale");

        require(
            _startTime >= block.timestamp,
            "start time should be greater than current time"
        );
        require(
            getTokenAddress() != address(0),
            "Token address has not initialized yet"
        );

        startTime = _startTime;
        isFinished = false;
        // Emit event
        emit EOpenSale(startTime, isStart());
    }

    ///////////////////////////////////////////////////
    // IN SALE
    // Write: User buy token by sending BNB
    // Convert Accepted bnb to Sale token
    function buyTokens() external payable {
        address payable senderAddress = _msgSender();
        uint256 acceptedAmount = msg.value;
        Whitelist memory whitelistSnapshot = whitelist[senderAddress];

        // Asserts
        require(isStart(), "Sale is not started yet");
        require(!isFinished, "Sale is finished");
        require(whitelistSnapshot.whitelist, "You are not in whitelist");
        uint256 tierAmount = getTierAmount(whitelistSnapshot.tier);
        require(
            acceptedAmount % tierAmount == 0,
            "You must send bnb equal to a multiple of tier amount"
        );

        uint256 tiersToPurchase = acceptedAmount / tierAmount;

        require(tiersToPurchase > 0, "You must purchase some tokens");
        require(
            tiersToPurchase <=
                whitelistSnapshot.maxPurchasableTiers -
                    whitelistSnapshot.tiersPurchased,
            "You can not purchase that many tokens"
        );

        // Update total participant
        if (whitelistSnapshot.tiersPurchased == 0) {
            totalParticipant = totalParticipant + 1;
        }

        // Update whitelist detail info
        whitelist[senderAddress].tiersPurchased += tiersToPurchase;
        // Update global info
        totalRaise = totalRaise + acceptedAmount;

        // Emit buy event
        emit EBuyTokens(
            senderAddress,
            acceptedAmount,
            totalRaise,
            totalParticipant
        );
    }

    // Write: Finish sale
    function finishSale() external onlyOwner returns (bool) {
        isFinished = true;
        // Emit event
        emit EFinishSale(isFinished);
        return isFinished;
    }

    // Write: Add Tiers
    function addTiers(uint256[] memory _tiers) external onlyOwner {
        require(!tiersAdded, "Tiers already added");
        require(!isStart(), "Sale is started");
        tiersAdded = true;
        tiers = _tiers;
    }

    ///////////////////////////////////////////////////
    // FREE STATE
    // Write: Add Whitelist
    function addWhitelist(WhitelistInput[] memory inputs) external onlyOwner {
        require(!isStart(), "Sale is started");
        require(tiersAdded, "Tiers not added yet");
        uint256 addressesLength = inputs.length;
        uint256 totalTiers = tiers.length;

        for (uint256 i = 0; i < addressesLength; i++) {
            WhitelistInput memory input = inputs[i];
            // require(input.tier <= totalTiers, "Invalid tier assigned");

            Whitelist memory _whitelist = Whitelist(
                input.maxPurchasableTiers,
                0,
                input.tier,
                input.wallet,
                true
            );
            whitelist[input.wallet] = _whitelist;
        }
        // Emit event
        emit EAddWhiteList(inputs);
    }

    // Write: Remove Whitelist
    function removeWhitelist(address[] memory addresses) external onlyOwner {
        require(!isStart(), "Sale is started");

        uint256 addressesLength = addresses.length;

        for (uint256 i = 0; i < addressesLength; i++) {
            address _address = addresses[i];
            Whitelist memory _whitelistSnapshot = whitelist[_address];
            whitelist[_address] = Whitelist(
                _whitelistSnapshot.maxPurchasableTiers,
                _whitelistSnapshot.tiersPurchased,
                _whitelistSnapshot.tier,
                _address,
                false
            );
        }
        // Emit event
        emit ERemoveWhiteList(addresses);
    }

    // Write: owner can withdraw all BNB
    function withdrawBNBBalance() external onlyOwner {
        address payable sender = _msgSender();

        uint256 balance = address(this).balance;
        sender.transfer(balance);

        // Emit event
        emit EWithdrawBNBBalance(sender, balance);
    }
}
