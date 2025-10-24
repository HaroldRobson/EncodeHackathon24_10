pragma solidity ^0.8.20;
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";



contract MusicNFT is ERC721URIStorage, ReentrancyGuard {

    IERC20 USDCtokens;
    address public owner;
    mapping(uint256 => bool) public isForSale;
    mapping(uint256 => uint256) public priceInUSDC;
    uint256 public tokenId;
    uint256 public MAX_MINT;
    uint256 public COST_TO_MINT;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address USDC, uint256 max_mint, uint256 cost_to_mint) ERC721("Baroque", "BRQ") {
        tokenId = 0;
        USDCtokens = IERC20(USDC);
        owner = msg.sender;
        MAX_MINT = max_mint;
        COST_TO_MINT = cost_to_mint;
    }

    function newSong(string memory uri, uint256 amount) public payable {
        require(amount < MAX_MINT, "TOO MANY TO MINT");
        require(msg.value > 0.1 ether, "we need a little bit of money please");
        for (uint256 i = 0; i < amount; i++) {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        tokenId = tokenId + 1;
        }

    }

    function transferMany(uint256 id_start, uint256 id_end, address to) public {
        for (uint256 i = id_start; i <= id_end; i++) {
            _transfer(msg.sender, to, i);
        }
            
    }

    function listForSale(uint256 id, uint256 price) public {
        require(ownerOf(id) == msg.sender, "YOU ARE NOT THE OWNER");
        isForSale[id] = true;
        priceInUSDC[id] = price;
        _approve(address(this), id, msg.sender);
    }

    function withdraw() public onlyOwner {
        USDCtokens.transfer(owner, USDCtokens.balanceOf(address(this)));
    }

    function unlist(uint256 id) public {
        require(ownerOf(id) == msg.sender, "YOU ARE NOT THE OWNER");
        isForSale[id] = false;
        _approve(address(0), id, msg.sender);
    }

    function listManyForSale(uint256 id_start, uint256 id_end, uint256 price) public {
        for (uint256 i = id_start; i <= id_end; i++) {
        require(ownerOf(i) == msg.sender, "YOU ARE NOT THE OWNER");
        isForSale[i] = true;
        priceInUSDC[i] = price;
        _approve(address(this), i, msg.sender);
        }
    }

    function whatIsForSale() public view returns (uint256[] memory) {
        uint256 arr_length = 0;
        for (uint256 i = 0; i < tokenId; i++) {
            if (isForSale[i]) {
                arr_length++;
            }
        }
        uint256[] memory arr = new uint256[](arr_length);
        uint256 arr_index = 0;
        for (uint256 i = 0; i < tokenId; i++) {
            if (isForSale[i]) {
               arr[arr_index] = i; 
               arr_index++;
            }
        }
        return arr;
    }

    function getPrice(uint256 id) public view returns (uint256) {
        return priceInUSDC[id] * 1050 / 1000;
    }

    function buy(uint256 id) public nonReentrant {
        require(isForSale[id], "NOT FOR SALE");
        address seller = ownerOf(id);
        isForSale[id] = false;
        uint256 costInUSDC_no_fee = priceInUSDC[id];
        uint256 costInUSDC = priceInUSDC[id] * 1050 / 1000;
        require(USDCtokens.transferFrom(msg.sender, address(this), costInUSDC), "ALERT: TRANSFER FAILED"); // this requires the customer to call (IERC20(USDC_ADDRESS)).approve(address(this), amountOfCBXOut * getPricePerTokenWithFee())
        USDCtokens.transfer(seller, costInUSDC_no_fee);
        this.safeTransferFrom(seller, msg.sender, id);
    }




}
