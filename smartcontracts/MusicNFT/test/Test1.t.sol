// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFT_Minter.sol";  // Import YOUR actual contract
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

// Mock USDC for testing
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1000000 * 10**6); // 1M USDC with 6 decimals
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

// Contract to test reentrancy attack
contract ReentrancyAttacker {
    MusicNFT public immutable nft;
    IERC20 public immutable usdc;
    uint256 public tokenIdToAttack;

    constructor(address _nftAddress, address _usdcAddress) {
        nft = MusicNFT(_nftAddress);
        usdc = IERC20(_usdcAddress);
    }

    function attack(uint256 _tokenId) public {
        // Approve the NFT contract to spend USDC on behalf of this attacker contract
        usdc.approve(address(nft), nft.getPrice(_tokenId));
        // Call the buy function, which will trigger the onERC721Received callback
        nft.buy(_tokenId);
    }

    // This function is called when the NFT is transferred to this contract
    // It will try to re-enter the buy function
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 _tokenId,
        bytes memory /* data */
    ) public returns (bytes4) {
        // Attempt to re-enter the buy function for the same token
        // This should be blocked by the nonReentrant modifier
        if (tokenIdToAttack == _tokenId) {
            nft.buy(_tokenId);
        }
        return this.onERC721Received.selector;
    }

    function setTokenId(uint256 id) public {
        tokenIdToAttack = id;
    }
}


contract MyNFTTest is Test {
    MusicNFT public nft;  // Use YOUR MyNFT contract
    MockUSDC public usdc;
    
    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    uint256 constant MAX_MINT_AMOUNT = 50;
    uint256 constant MINT_COST = 1 ether; // This value is set in constructor but not used in contract logic
    
    uint256 constant INITIAL_BALANCE = 10000 * 10**6; // 10,000 USDC
    uint256 constant ETH_FUNDING = 10 ether;
    string constant TEST_URI = "ipfs://QmTest123";
    string constant TEST_URI_2 = "ipfs://QmTest456";
    
    function setUp() public {
        // Deploy mock USDC
        usdc = new MockUSDC();
        
        // Deploy YOUR NFT contract with mock USDC address and new constructor params
        nft = new MusicNFT(address(usdc), MAX_MINT_AMOUNT, MINT_COST);
        
        // Setup test accounts with USDC
        usdc.mint(alice, INITIAL_BALANCE);
        usdc.mint(bob, INITIAL_BALANCE);
        usdc.mint(charlie, INITIAL_BALANCE);
        
        // Fund accounts with Ether for minting fee
        vm.deal(alice, ETH_FUNDING);
        vm.deal(bob, ETH_FUNDING);
        vm.deal(charlie, ETH_FUNDING);

        // Label addresses for better test output
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(address(nft), "NFT Contract");
        vm.label(address(usdc), "USDC");
    }
    // ============ Constructor Tests ============
    
    function test_Constructor() public {
        assertEq(nft.name(), "Baroque");
        assertEq(nft.symbol(), "BRQ");
        assertEq(nft.owner(), owner);
        assertEq(nft.tokenId(), 0);
        assertEq(nft.MAX_MINT(), MAX_MINT_AMOUNT);
    }
    
    // ============ Minting Tests ============
    
    function test_NewSongSingle() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.tokenURI(0), TEST_URI);
        assertEq(nft.tokenId(), 1);
    }
    
    function test_NewSongMultiple() public {
        uint256 amount = 5;
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, amount);
        
        for (uint256 i = 0; i < amount; i++) {
            assertEq(nft.ownerOf(i), alice);
            assertEq(nft.tokenURI(i), TEST_URI);
        }
        assertEq(nft.tokenId(), amount);
    }

    function test_FailNewSongNotEnoughEth() public {
        vm.prank(alice);
        vm.expectRevert("we need a little bit of money please");
        nft.newSong{value: 0.1 ether}(TEST_URI, 1);
    }

    function test_FailNewSongTooManyToMint() public {
        vm.prank(alice);
        vm.expectRevert("TOO MANY TO MINT");
        nft.newSong{value: 0.2 ether}(TEST_URI, MAX_MINT_AMOUNT); // amount must be < MAX_MINT
    }
    
    function test_NewSongZeroAmount() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 0);
        assertEq(nft.tokenId(), 0);
    }
    
    function test_NewSongFromMultipleUsers() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 2);
        
        vm.prank(bob);
        nft.newSong{value: 0.2 ether}(TEST_URI_2, 3);
        
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), bob);
        assertEq(nft.ownerOf(3), bob);
        assertEq(nft.ownerOf(4), bob);
        assertEq(nft.tokenId(), 5);
    }
    
    // ============ Transfer Tests ============
    
    function test_TransferMany() public {
        // Mint 5 NFTs to alice
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 5);
        
        // Transfer tokens 1-3 to bob
        vm.prank(alice);
        nft.transferMany(1, 3, bob);
        
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), bob);
        assertEq(nft.ownerOf(2), bob);
        assertEq(nft.ownerOf(3), bob);
        assertEq(nft.ownerOf(4), alice);
    }
    
    function test_TransferManyNotOwner() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 3);
        
        vm.prank(bob);
        // Updated to expect the custom error from OpenZeppelin v5
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721IncorrectOwner.selector, bob, 0, alice));
        nft.transferMany(0, 2, charlie);
    }
    
    function test_TransferManySingleToken() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 2);
        
        vm.prank(alice);
        nft.transferMany(0, 0, bob);
        
        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.ownerOf(1), alice);
    }
    
    // ============ Listing Tests ============
    
    function test_ListForSale() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        uint256 price = 100 * 10**6; // 100 USDC
        vm.prank(alice);
        nft.listForSale(0, price);
        
        assertTrue(nft.isForSale(0));
        assertEq(nft.priceInUSDC(0), price);
    }
    
    function test_ListForSaleNotOwner() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        vm.prank(bob);
        vm.expectRevert("YOU ARE NOT THE OWNER");
        nft.listForSale(0, 100 * 10**6);
    }
    
    function test_ListManyForSale() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 5);
        
        uint256 price = 50 * 10**6; // 50 USDC
        vm.prank(alice);
        nft.listManyForSale(1, 3, price);
        
        assertFalse(nft.isForSale(0));
        assertTrue(nft.isForSale(1));
        assertTrue(nft.isForSale(2));
        assertTrue(nft.isForSale(3));
        assertFalse(nft.isForSale(4));
        
        assertEq(nft.priceInUSDC(1), price);
        assertEq(nft.priceInUSDC(2), price);
        assertEq(nft.priceInUSDC(3), price);
    }
    
    function test_ListManyForSaleNotOwner() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 3);
        
        vm.prank(bob);
        vm.expectRevert("YOU ARE NOT THE OWNER");
        nft.listManyForSale(0, 2, 100 * 10**6);
    }
    
    // ============ Unlist Tests ============
    
    function test_Unlist() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        uint256 price = 100 * 10**6;
        vm.prank(alice);
        nft.listForSale(0, price);
        assertTrue(nft.isForSale(0));
        
        vm.prank(alice);
        nft.unlist(0);
        assertFalse(nft.isForSale(0));
    }
    
    function test_UnlistNotOwner() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        vm.prank(alice);
        nft.listForSale(0, 100 * 10**6);
        
        vm.prank(bob);
        vm.expectRevert("YOU ARE NOT THE OWNER");
        nft.unlist(0);
    }
    
    // ============ View Functions Tests ============
    
    function test_WhatIsForSale() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 5);
        
        // List tokens 0, 2, 4
        vm.prank(alice);
        nft.listForSale(0, 100 * 10**6);
        vm.prank(alice);
        nft.listForSale(2, 200 * 10**6);
        vm.prank(alice);
        nft.listForSale(4, 300 * 10**6);
        
        uint256[] memory forSale = nft.whatIsForSale();
        assertEq(forSale.length, 3);
        assertEq(forSale[0], 0);
        assertEq(forSale[1], 2);
        assertEq(forSale[2], 4);
    }
    
    function test_WhatIsForSaleEmpty() public {
        uint256[] memory forSale = nft.whatIsForSale();
        assertEq(forSale.length, 0);
    }
    
    function test_GetPrice() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        uint256 basePrice = 100 * 10**6; // 100 USDC
        vm.prank(alice);
        nft.listForSale(0, basePrice);
        
        uint256 priceWithFee = nft.getPrice(0);
        assertEq(priceWithFee, basePrice * 1050 / 1000); // 5% fee
        assertEq(priceWithFee, 105 * 10**6); // 105 USDC
    }
    
    // ============ Buy Tests ============
    
    function test_BuySuccess() public {
        // Setup: Alice mints and lists NFT
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        uint256 price = 100 * 10**6; // 100 USDC
        vm.prank(alice);
        nft.listForSale(0, price);
        
        // Bob approves and buys
        uint256 totalCost = price * 1050 / 1000; // 105 USDC with fee
        vm.startPrank(bob);
        usdc.approve(address(nft), totalCost);
        
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        uint256 bobBalanceBefore = usdc.balanceOf(bob);
        uint256 contractBalanceBefore = usdc.balanceOf(address(nft));
        
        nft.buy(0);
        vm.stopPrank();
        
        // Verify ownership transfer
        assertEq(nft.ownerOf(0), bob);
        assertFalse(nft.isForSale(0));
        
        // Verify USDC transfers
        assertEq(usdc.balanceOf(alice), aliceBalanceBefore + price); // Seller gets base price
        assertEq(usdc.balanceOf(bob), bobBalanceBefore - totalCost); // Buyer pays with fee
        assertEq(usdc.balanceOf(address(nft)), contractBalanceBefore + (totalCost - price)); // Contract keeps fee
    }
    
    function test_BuyNotForSale() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        vm.prank(bob);
        vm.expectRevert("NOT FOR SALE");
        nft.buy(0);
    }
    
    function test_BuyInsufficientAllowance() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        uint256 price = 100 * 10**6;
        vm.prank(alice);
        nft.listForSale(0, price);
        
        // Bob approves less than needed
        vm.startPrank(bob);
        usdc.approve(address(nft), price); // Should be price * 1.05
        
        // Expect the custom error from OpenZeppelin v5
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(nft), price, price * 1050 / 1000)
        );
        nft.buy(0);
        vm.stopPrank();
    }
    
    function test_BuyInsufficientBalance() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        uint256 price = INITIAL_BALANCE * 2; // More than Bob has
        vm.prank(alice);
        nft.listForSale(0, price);
        
        uint256 totalCost = price * 1050 / 1000;
        vm.startPrank(bob);
        usdc.approve(address(nft), totalCost);
        
        // Expect the custom error from OpenZeppelin v5
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, bob, INITIAL_BALANCE, totalCost)
        );
        nft.buy(0);
        vm.stopPrank();
    }
    
    function test_BuyFromSameOwner() public {
        // Edge case: owner tries to buy their own NFT
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        uint256 price = 100 * 10**6;
        vm.prank(alice);
        nft.listForSale(0, price);
        
        uint256 totalCost = price * 1050 / 1000;
        vm.startPrank(alice);
        usdc.approve(address(nft), totalCost);
        
        // This should work but is economically pointless (alice pays fee to herself minus contract fee)
        nft.buy(0);
        vm.stopPrank();
        
        assertEq(nft.ownerOf(0), alice);
        assertFalse(nft.isForSale(0));
    }
    
    function test_MultipleBuys() public {
        // Alice mints 3 NFTs
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 3);
        
        // List all 3 with different prices
        vm.startPrank(alice);
        nft.listForSale(0, 100 * 10**6);
        nft.listForSale(1, 200 * 10**6);
        nft.listForSale(2, 300 * 10**6);
        vm.stopPrank();
        
        // Bob buys token 0
        vm.startPrank(bob);
        usdc.approve(address(nft), 105 * 10**6);
        nft.buy(0);
        vm.stopPrank();
        
        // Charlie buys token 2
        vm.startPrank(charlie);
        usdc.approve(address(nft), 315 * 10**6);
        nft.buy(2);
        vm.stopPrank();
        
        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.ownerOf(1), alice); // Still owned by alice
        assertEq(nft.ownerOf(2), charlie);
        
        assertFalse(nft.isForSale(0));
        assertTrue(nft.isForSale(1)); // Still for sale
        assertFalse(nft.isForSale(2));
    }
    
    // ============ Withdraw Tests ============
    
    function test_Withdraw() public {
        // Setup: Generate some fees through sales
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        uint256 price = 1000 * 10**6; // 1000 USDC
        vm.prank(alice);
        nft.listForSale(0, price);
        
        uint256 totalCost = price * 1050 / 1000; // 1050 USDC
        vm.startPrank(bob);
        usdc.approve(address(nft), totalCost);
        nft.buy(0);
        vm.stopPrank();
        
        uint256 contractBalance = usdc.balanceOf(address(nft));
        uint256 expectedFee = 50 * 10**6; // 50 USDC fee
        assertEq(contractBalance, expectedFee);
        
        uint256 ownerBalanceBefore = usdc.balanceOf(owner);
        
        // Owner withdraws
        nft.withdraw();
        
        assertEq(usdc.balanceOf(address(nft)), 0);
        assertEq(usdc.balanceOf(owner), ownerBalanceBefore + expectedFee);
    }
    
    function test_WithdrawNotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.withdraw();
    }
    
    function test_WithdrawEmpty() public {
        uint256 ownerBalanceBefore = usdc.balanceOf(owner);
        nft.withdraw();
        assertEq(usdc.balanceOf(owner), ownerBalanceBefore);
    }
    
    // ============ Edge Cases and Invariants ============
    
    function test_CannotBuyAfterTransfer() public {
        // Alice mints and lists
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        vm.prank(alice);
        nft.listForSale(0, 100 * 10**6);
        
        // Alice transfers to Bob (but NFT is still marked for sale)
        vm.prank(alice);
        nft.transferFrom(alice, bob, 0);
        
        // Charlie tries to buy - should fail because Alice no longer owns it
        vm.startPrank(charlie);
        usdc.approve(address(nft), 105 * 10**6);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, address(nft), 0));
        nft.buy(0);
        vm.stopPrank();
    }
    
    function test_RelistAfterBuy() public {
        // Alice mints and lists
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        vm.prank(alice);
        nft.listForSale(0, 100 * 10**6);
        
        // Bob buys
        vm.startPrank(bob);
        usdc.approve(address(nft), 105 * 10**6);
        nft.buy(0);
        vm.stopPrank();
        
        // Bob relists at higher price
        vm.prank(bob);
        nft.listForSale(0, 200 * 10**6);
        
        assertTrue(nft.isForSale(0));
        assertEq(nft.priceInUSDC(0), 200 * 10**6);
        
        // Charlie buys from Bob
        vm.startPrank(charlie);
        usdc.approve(address(nft), 210 * 10**6);
        nft.buy(0);
        vm.stopPrank();
        
        assertEq(nft.ownerOf(0), charlie);
        assertFalse(nft.isForSale(0));
    }
    
    function testPriceOverflow() public {
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        // Set a very high price that will overflow with 5% fee
        uint256 maxPrice = type(uint256).max / 1050 * 1000 + 1; // Just over the safe limit
        vm.prank(alice);
        nft.listForSale(0, maxPrice);
        
        // This should overflow
        vm.expectRevert(stdError.arithmeticError);
        nft.getPrice(0);
    }

    function test_FailReentrancyAttackOnBuy() public {
        // 1. Deploy attacker contract
        ReentrancyAttacker attacker = new ReentrancyAttacker(address(nft), address(usdc));
        vm.label(address(attacker), "Attacker");

        // 2. Fund attacker with USDC
        usdc.mint(address(attacker), INITIAL_BALANCE);

        // 3. Alice mints and lists an NFT
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        uint256 tokenId = 0;

        uint256 price = 100 * 10**6; // 100 USDC
        vm.prank(alice);
        nft.listForSale(tokenId, price);

        // 4. Prepare and launch the attack
        attacker.setTokenId(tokenId);
        
        // 5. Expect the reentrancy guard to revert the call
        vm.expectRevert(); 
        attacker.attack(tokenId);
    }
    
    // ============ Fuzz Tests ============
    
    function test_FuzzNewSong(string memory uri, uint8 amount) public {
        vm.assume(amount > 0 && amount < MAX_MINT_AMOUNT); // Must mint at least 1, and be under the limit
        
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(uri, amount);
        
        for (uint256 i = 0; i < amount; i++) {
            assertEq(nft.ownerOf(i), alice);
            assertEq(nft.tokenURI(i), uri);
        }
        assertEq(nft.tokenId(), amount);
    }

    function test_FuzzListForSale(uint256 price) public {
        // More restrictive bound to prevent overflow
        price = bound(price, 1, type(uint256).max / 2000);
        
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        vm.prank(alice);
        nft.listForSale(0, price);
        
        assertTrue(nft.isForSale(0));
        assertEq(nft.priceInUSDC(0), price);
        
        // Only check getPrice if it won't overflow
        if (price <= type(uint256).max / 1050 * 1000) {
            assertEq(nft.getPrice(0), price * 1050 / 1000);
        }
    }
   
    function test_FuzzBuy(uint128 price) public {
        vm.assume(price > 0 && price < INITIAL_BALANCE / 2); // Ensure buyer has enough
        
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 1);
        
        vm.prank(alice);
        nft.listForSale(0, price);
        
        uint256 totalCost = uint256(price) * 1050 / 1000;
        vm.startPrank(bob);
        usdc.approve(address(nft), totalCost);
        nft.buy(0);
        vm.stopPrank();
        
        assertEq(nft.ownerOf(0), bob);
        assertFalse(nft.isForSale(0));
    }
    
    // ============ Integration Tests ============
    
    function test_FullMarketplaceFlow() public {
        // 1. Alice mints collection
        vm.prank(alice);
        nft.newSong{value: 0.2 ether}(TEST_URI, 10);
        
        // 2. Alice transfers some to Bob as gifts
        vm.prank(alice);
        nft.transferMany(5, 7, bob);
        
        // 3. Alice lists her remaining NFTs
        vm.prank(alice);
        nft.listManyForSale(0, 4, 100 * 10**6);
        
        // 4. Bob lists his NFTs at different price
        vm.prank(bob);
        nft.listManyForSale(5, 7, 150 * 10**6);
        
        // 5. Check what's for sale
        uint256[] memory forSale = nft.whatIsForSale();
        assertEq(forSale.length, 8); // 5 from Alice + 3 from Bob
        
        // 6. Charlie buys from both
        vm.startPrank(charlie);
        usdc.approve(address(nft), 1000 * 10**6); // Approve enough for multiple purchases
        
        nft.buy(0); // Buy from Alice
        nft.buy(5); // Buy from Bob
        vm.stopPrank();
        
        assertEq(nft.ownerOf(0), charlie);
        assertEq(nft.ownerOf(5), charlie);
        
        // 7. Owner withdraws accumulated fees
        uint256 expectedFees = (100 * 10**6 * 50 / 1000) + (150 * 10**6 * 50 / 1000);
        uint256 ownerBalanceBefore = usdc.balanceOf(owner); 
        nft.withdraw();
        assertEq(usdc.balanceOf(owner), expectedFees + ownerBalanceBefore);
        
        // 8. Charlie resells one
        vm.prank(charlie);
        nft.listForSale(0, 200 * 10**6);
        
        vm.startPrank(alice);
        usdc.approve(address(nft), 210 * 10**6);
        nft.buy(0);
        vm.stopPrank();
        
        assertEq(nft.ownerOf(0), alice); // Back to Alice
    }
}
