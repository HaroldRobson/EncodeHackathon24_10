MEOWWWWWWWWW
OK so music app
smart contract

you have these basic functions in NFT_Minter.sol which is the only file:

 # UPLOAD MUSIC
 - newSong(uri, amount)
  - uri - ipfs uri from uploading stuff there first
  - amount - amount of NFTs for this specific song you wanna mint
  - sets the caller of this function as the owner of the NFTs
  - costs money (is payable) to stop people spamming it - sent eth along with the function call.


 # SELL MUSIC
 - listForSale(id, price)
  - id is NFT's id
  - price is in USDC so 6 decimal places - BE CAREFUL
- unlist(id)
 - gets rid of your NFT with id = id to be unlisted from sale
- listManyForSale(start, end, price)
 - goes from id start to end inclusive and does the same as listForSale
 - useful if you issued a load of NFTs for a specific song and want to list them all at once
- Note that with all of these, USDC is transferred autopmatically (minus our fee) to seller once someone has bought the NFt



 # BUY MUSIC
 - whatIsForSale()
  - returns array of NFT ids currently for sale
 - getPrice(id)
  - gives you the price with our fee in USDC of the nft
 - buy(id)
  - requires user to already approve on USDC the transfer of the correct amount of USDC to this contract's address
  - transfers ownership of NFT to user
 - tokenURI(id) just gives the IPFS uri of the nft - inherited from ERC721URIStorage 


