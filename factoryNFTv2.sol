pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "@openzeppelin/contracts/access/Ownable.sol";

    //Trinket interface
    interface ITrinket {
        function claimTrinkets(uint) external;
    }

    //nibbles interface
    interface INibbles {              
        function transfer(address to, uint amount) external returns (bool);
        function transferFrom(address from, address to, uint wad) external returns (bool);
        function balanceOf(address user) external view returns (uint);
        function approve(address _spender, uint _value) external returns (bool);
        function increaseApproval (address _spender, uint _value) external returns (bool);
    }
contract FactoryNFTv2 is ERC721URIStorage, Ownable, ERC721Enumerable { 

    using Counters for Counters.Counter; 
    Counters.Counter private _tokenIds;

    //minting
    bool mintLive = false;
    //revelaed 
    bool reveal = false;

    //set mint price
    uint mintPrice = 500000000000000000;
    //set Maximum mint amount
    uint maxMintAmount = 20;
    //set max total supply of rats
    uint maxTotalSupply = 200;
    //set maxID revealed
    uint maxIdRevealed = 0;
    //base URL For metadata
    string baseURL;
    //base URL For metadata
    string preRevealURI;
    //Trinket address
    address trinketAddr;
    //Nibbles Address
    address nibblesAddr;

    //levelcostperams
    uint baseLevelCost = 5000;
    uint mod = 100;

    //rat level data
    mapping (uint => uint) public ratLevel;

    //minttimestamp
    mapping (uint => uint) public ratMintTimeStamp;

    function setTrinketAddr(address _trinketAddr) onlyOwner external {
        trinketAddr = _trinketAddr;
    }

    function setNibblesAddr(address _nibblesAddr) onlyOwner external {
        nibblesAddr = _nibblesAddr;
    }

    function setBaseLevelCost(uint _cost) onlyOwner external {
        baseLevelCost = _cost;
    }
    function setMod(uint _mod) onlyOwner external {
       mod = _mod;
    }

    function setMaxReveal (uint _maxRevealId) onlyOwner external{
        maxIdRevealed = _maxRevealId;
    }
    function maxReveal () public view returns(uint maxids){
        return maxIdRevealed;
    }
   function setMintLive () onlyOwner external{
       require (bytes(preRevealURI).length > 0, "pre reveal URI has not been set");
        if (mintLive == true){
            mintLive = false;
        }
        else {
         mintLive = true;
        }
    }
    
    function setMaxSupply (uint _newSupply) onlyOwner external{
        require (_newSupply <= 10000, "Cannot exceed 10k");
        maxTotalSupply = _newSupply;
    }
    function setMintPrice(uint _newPrice) onlyOwner external{
        require (_newPrice > 100000000000000000, "cannot be lower than 0.1 avax");
        mintPrice = _newPrice;
    }

    constructor() ERC721("AVAX Nibblers", "NIBBLERS") {   
    }       

   

    function createToken(uint256 numberOfNfts) public payable returns (bool success) {
        
        require(numberOfNfts > 0, "can't mint 0");
        require(numberOfNfts <= maxMintAmount, "Max mint exceeded");
        require(msg.value >= (numberOfNfts * mintPrice), "Not enough AVAX sent; check price!"); 
        require(mintLive == true);
        for (uint i = 0; i < numberOfNfts; i++) {
            _tokenIds.increment();
            require(_tokenIds.current() <= maxTotalSupply, "Max Supply Exceeded");
            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            ratLevel[newItemId] = 1;
            ratMintTimeStamp[newItemId] = block.timestamp;
        }  
        return true;  
    }

    function mintTime(uint _id) external view returns(uint){
        return ratMintTimeStamp[_id];
    }

    function setBaseUrl(string memory url) onlyOwner external {
        baseURL = url;
    }
    
    function setPreRevealUrl(string memory url) onlyOwner external {
        preRevealURI = url;
    }



    function currentLevel(uint id) public view returns (uint) {
     return ratLevel[id];
    }


    
    function levelUp(uint id) public payable {
        ITrinket(trinketAddr).claimTrinkets(id);
        uint cost = (levelUpCost(id)) * 1000000000000000000;
        INibbles(nibblesAddr).transferFrom(msg.sender, address(this), cost);
        ratLevel[id] = ratLevel[id]+1;
    }

    function levelUpCost(uint id) public view returns (uint) {
        uint levelMultiplier = (ratLevel[id] - 1) * (50 + ratLevel[id]);
        uint levelPremium = (((baseLevelCost * levelMultiplier) /100) * mod) / 100;
        uint levelCost = baseLevelCost + levelPremium;
        return ((levelCost * mod) / 100);
    }



    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURL;
    }

    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory uri){
        if (tokenId > maxIdRevealed){
            return preRevealURI; 
        } else {
            string memory baseURI = _baseURI();
            string memory stringURInumber = Strings.toString(tokenId);
            string memory URIend = ".json";
            string memory IdURI = string(abi.encodePacked(baseURI, stringURInumber, URIend));
            return IdURI;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function transferAvax(address payable _to, uint256 _value) public onlyOwner returns (bool success) {
        _to.transfer(_value);
        return true;
    }

}
