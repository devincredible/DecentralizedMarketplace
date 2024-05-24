// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Marketplace {
    event RegisterUser(address indexed user, string indexed name);
    event RegisterItem(
        uint indexed id,
        string indexed name,
        string description,
        uint price,
        address indexed owner
    );
    event BuyItem(address indexed newOwner, address indexed oldOwner, uint id);
    event Withdraw(address indexed user, uint256 bal);

    struct User {
        string name;
    }

    struct Item {
        string name;
        string description;
        uint256 price;
        bool isAvailable;
        address owner;
    }

    mapping(address => User) users;
    mapping(string => bool) isRegistered;
    mapping(uint => Item) items;
    mapping(address => uint256) balances;

    uint256 itemCnt;

    constructor() {
        itemCnt = 0;
    }

    modifier notEmpty(string memory _str) {
        require(bytes(_str).length > 0, "empty string");
        _;
    }

    // register user
    function registerUser(string memory _name) public notEmpty(_name) {
        require(bytes(users[msg.sender].name).length > 0, "already registered");
        require(!isRegistered[_name], "not unique user name");

        isRegistered[_name] = true;
        users[msg.sender] = User(_name);

        emit RegisterUser(msg.sender, _name);
    }

    // register item
    function registerItem(
        string memory _name,
        string memory _description,
        uint256 _price
    ) public notEmpty(_name) notEmpty(_description) {
        require(_price > 0, "not vaild price");

        Item memory _item = Item(
            _name,
            _description,
            _price,
            false,
            msg.sender
        );
        items[itemCnt] = _item;
        itemCnt++;

        emit RegisterItem(itemCnt - 1, _name, _description, _price, msg.sender);
    }

    // buy an item from another user
    function buyItem(uint256 _id) public payable {
        require(_id < itemCnt, "not valid id");
        require(
            items[_id].owner != msg.sender,
            "the owner cannot try to buy his item"
        );
        require(msg.value > items[_id].price, "not enough token");
        require(items[_id].isAvailable, "not for sale");

        address owner = items[_id].owner;

        balances[owner] += items[_id].price;
        items[_id].isAvailable = false;
        items[_id].owner = msg.sender;

        emit BuyItem(msg.sender, owner, _id);
    }

    // set state : true for 'available', false for 'sold'
    function setState(uint256 _id, bool _state) public {
        require(_id < itemCnt, "not valid id");
        require(items[_id].owner == msg.sender, "only the owner can set state");

        items[_id].isAvailable = _state;
    }

    // withdraw ETH on his account
    function withdraw() public {
        uint256 bal = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    // get information using item ID
    function getInformation(
        uint256 _id
    )
        public
        view
        returns (
            string memory name,
            string memory description,
            bool isAvailable,
            address owner
        )
    {
        return (
            items[_id].name,
            items[_id].description,
            items[_id].isAvailable,
            items[_id].owner
        );
    }
}
