pragma ton-solidity = 0.47.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "include.sol";

interface INftRoot{
    function resolveCodeHashIndex(
        address addrRoot,
        address addrOwner
    ) external view returns (uint256 codeHashIndex);
}

interface IData{
    function getOwner() external view returns(address addrOwner);
}

contract AuthDebot is Debot {

    string _debotName = "Itgold nft authentication debot";
    address _supportAddr = address.makeAddrStd(0, 0x5fb73ece6726d59b877c8194933383978312507d06dda5bcf948be9d727ede4b);
    uint256 _ownerPubkey = tvm.pubkey();

    address[] _nftList;
    address _nftRoot = address(0);
    address _userAddr;

    AccData[] _indexes;

    bytes _icon;

    function start() public override {
        getAddress();
    }

    function getAddress() public {
        UserInfo.getAccount(tvm.functionId(setAddress));
    }

    function setAddress(address value) public {
        _userAddr = value;
        checkOwnershipUseRoot();
    }

    function checkOwnershipUseRoot() public {
        if (_nftRoot.value != 0) {
            getIndexCodeHash(tvm.functionId(onGetCodeHashSuccess), tvm.functionId(onGetCodeHashError));
        } else {
            checkOwnershipUseNfts();
        }
    }

    function getIndexCodeHash(uint32 answerId, uint32 errorId) public view {
        optional(uint256) none;
        INftRoot(_nftRoot).resolveCodeHashIndex{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: errorId
        }(_nftRoot, _userAddr);
    }

    function onGetCodeHashError(uint32 sdkError, uint32 exitCode) public {
        _indexes[0] = _indexes[_indexes.length - 1];
        _indexes.pop();
        checkIndexes();
    }

    function onGetCodeHashSuccess(uint256 indexCodeHash) public {
        uint256 _codeHashIndex = indexCodeHash;
        buildIndexCodeData(_codeHashIndex);
    } 

    function buildIndexCodeData(uint256 indexCodeHash) public{
        Sdk.getAccountsDataByHash(
            tvm.functionId(setAccounts),
            indexCodeHash,
            address.makeAddrStd(0, 0)
        );
    }

    function setAccounts(AccData[] accounts) public {

        _indexes = accounts;
        checkIndexes();
    }

    function checkIndexes() public {
        if(_indexes.length != 0){
            Sdk.getAccountType(tvm.functionId(checkIndexAddressStatus), _indexes[0].id);
        } else {
            checkOwnershipUseNfts();
        }
    }

    function checkIndexAddressStatus(int8 acc_type) public {
        if (checkIndexStatus(acc_type)) {
            foo();
        } else {
            _indexes[0] = _indexes[_indexes.length - 1];
            _indexes.pop();
            checkIndexes();
        }
    }

    function checkIndexStatus(int8 acc_type) public returns (bool) {
        if (acc_type == -1)  {
            Terminal.print(0, "Address is inactive");
            return false;
        }
        if (acc_type == 0) {
            Terminal.print(0, "Address is unitialized");
            return false;
        }
        if (acc_type == 2) {
            Terminal.print(0, "Address is frozen");
            return false;
        }
        return true;
    }

    function checkOwnershipUseNfts() public {
        if (_nftList.length != 0) {
            getOwner(tvm.functionId(onGetOwnerSuccess), tvm.functionId(onGetOwnerError));
        } else {
            dontHaveNft();
        }
    }

    function getOwner(uint32 answerId, uint32 errorId) public view {
        optional(uint256) none;
        IData(_nftList[0]).getOwner{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: errorId
        }();
    }

    function onGetOwnerSuccess(address addrOwner) public {
        if (addrOwner == _userAddr) {
            foo();
        } else {
            _nftList[0] = _nftList[_nftList.length - 1];
            _nftList.pop();
            checkOwnershipUseNfts();
        }
    }

    function onGetOwnerError(uint32 sdkError, uint32 exitCode) public {
        _nftList[0] = _nftList[_nftList.length - 1];
        _nftList.pop();
        checkOwnershipUseNfts();
    }

    function foo() public {
        Terminal.print(0, "Запрограммируйте поведение тут");
    }

    function dontHaveNft() public {
        Terminal.print(0, "Forbitten! у вас нет нужной NFT");
    }

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = _debotName;
        version = "1.0";
        publisher = "https://itgold.io/";
        key = "User authentication use nft";
        author = "https://itgold.io/";
        support = _supportAddr;
        hello = "Hello, i'm itgold nft authentication debot";
        language = "en";
        dabi = m_debotAbi.get();
        icon = _icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, UserInfo.ID ];
    }
    
    function noop(string value) public  {
        value;
        Terminal.input(tvm.functionId(noop), "", false);
    }

    function setNftRootAddr(address nftRoot) public onlyOwner {
        tvm.accept();
        _nftRoot = nftRoot;
    }

    function setNftList(address[] nftList) public onlyOwner {
        tvm.accept();
        _nftList = nftList;
    }

    function setOwnerPubkey(uint256 ownerPubkey) public onlyOwner {
        tvm.accept();
        _ownerPubkey = ownerPubkey;
    }

    function setIcon(bytes icon) public onlyOwner {
        tvm.accept();
        _icon = icon;
    }

    function burn(address dest) public onlyOwner {
        tvm.accept();
        selfdestruct(dest);
    }

    modifier onlyOwner() {
        require(msg.pubkey() == _ownerPubkey, 100);
        _;
    }

}