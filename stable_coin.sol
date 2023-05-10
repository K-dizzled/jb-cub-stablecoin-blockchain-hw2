pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KDCoin is IERC20, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public override totalSupply;
    uint private _reserve;
    uint public peg;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    event Minted(uint amount);
    event Burned(uint amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        uint _peg
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
        _reserve = _initialSupply;
        peg = _peg;
        balanceOf[msg.sender] = totalSupply;
    }

    function reserve() public view returns (uint) {
        return _reserve;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function mint(uint amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(reserve() >= amount, "Insufficient reserve");
        _reserve = _reserve.sub(amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        emit Minted(amount);
    }

    function burn(uint amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        _reserve = _reserve.add(amount);
        emit Burned(amount);
    }

    function adjustSupply(uint amount) public onlyOwner {
        if (amount > totalSupply) {
            mint(amount - totalSupply);
        } else if (amount < totalSupply) {
            burn(totalSupply - amount);
        }
    }
}