//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//import "../../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
//import "../../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "../../../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "./../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "../../../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICurrenciesERC20.sol";
import "./../node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 *      CurrenciesERC20
 * @title CurrenciesERC20
 * @author JackBekket
 * @dev This contract allow to use erc20 tokens as a currency in crowdsale-like contracts
 *
 */
contract CurrenciesERC20 is ReentrancyGuard, Ownable, ERC165 {
    using SafeMath for uint256;
    //  using SafeERC20 for IERC20;

    // Interface to currency token
    //IERC20 public _currency_token;

    // Supported erc20 currencies: .. to be extended.  This is hard-coded values
    /**
     * @dev Hardcoded (not-extetiable after deploy) erc20 currencies
     */
    enum CurrencyERC20 {
        USDT,
        USDC,
        DAI,
        MST,
        WETH,
        WBTC
    }

    struct CurrencyERC20_Custom {
        address contract_address;
        IERC20Metadata itoken; // contract interface
    }

    // map from currency to contract
    mapping(CurrencyERC20 => IERC20Metadata) public _currencies_hardcoded; // should be internal?

    // mapping from name to currency contract (protected)
    mapping(string => CurrencyERC20_Custom) public _currencies_custom;

    // mapping from name to currency contract defined by users (not protected against scum)
    mapping(string => CurrencyERC20_Custom) public _currencies_custom_user;

    // mapping from currency contract address to flag
    mapping(address => bool) public isCurrency;

    // mapping from address to currency
    mapping(address => IERC20Metadata) public _currencies_by_address;

    bytes4 private _INTERFACE_ID_CURRENCIES = 0x033a36bd;

    /// @dev interface of method_id for token transfer function (ERC20 standard)
    bytes4 public _INTEFACE_ID_TRANSFER_ERC20 = 0xa9059cbb;

    // doesn't work with tether
    function AddCustomCurrency(address _token_contract) public {
        IERC20Metadata _currency_contract = IERC20Metadata(_token_contract);

        // if (_currency_contract.name != '0x0')

        string memory _name_c = _currency_contract.name(); // @note -- some contracts just have name as public string, but do not have name() function!!! see difference between 0.4.0 and 0.8.0 OZ standarts need future consideration
        //  uint8 _dec = _currency_contract.decimals();

        address _owner_c = owner();
        if (msg.sender == _owner_c) {
            require(
                _currencies_custom[_name_c].contract_address == address(0),
                "AddCustomCurrency[admin]: Currency token contract with this address is already exists"
            );
            _currencies_custom[_name_c].itoken = _currency_contract;
            //   _currencies_custom[_name_c].decimals = _dec;
            _currencies_custom[_name_c].contract_address = _token_contract;
        } else {
            require(
                _currencies_custom_user[_name_c].contract_address == address(0),
                "AddCustomCurrency[user]: Currency token contract with this address is already exists"
            );
            _currencies_custom_user[_name_c].itoken = _currency_contract;
            //  _currencies_custom_user[_name_c].decimals = _dec;
            _currencies_custom_user[_name_c].contract_address = _token_contract;
        }

        isCurrency[_token_contract] = true;
        _currencies_by_address[_token_contract] = _currency_contract;

    }

    constructor(
        address US_Tether,
        address US_Circle,
        address DAI,
        address W_Ethereum,
        address MST,
        address WBTC
    ) {
        require(US_Tether != address(0), "USDT contract address is zero!");
        require(US_Circle != address(0), "US_Circle contract address is zero!");
        require(DAI != address(0), "DAI contract address is zero!");
        require(
            W_Ethereum != address(0),
            "W_Ethereum contract address is zero!"
        );
        require(MST != address(0), "MST contract address is zero!");
        require(WBTC != address(0), "WBTC contract address is zero!");

        _currencies_hardcoded[CurrencyERC20.USDT] = IERC20Metadata(US_Tether);
        _currencies_hardcoded[CurrencyERC20.USDT] == IERC20Metadata(US_Tether); // ?
        _currencies_hardcoded[CurrencyERC20.USDC] = IERC20Metadata(US_Circle);
        _currencies_hardcoded[CurrencyERC20.DAI] = IERC20Metadata(DAI);
        _currencies_hardcoded[CurrencyERC20.WETH] = IERC20Metadata(W_Ethereum);
        _currencies_hardcoded[CurrencyERC20.MST] = IERC20Metadata(MST);
        _currencies_hardcoded[CurrencyERC20.WBTC] = IERC20Metadata(WBTC);

        isCurrency[US_Tether] = true;
        isCurrency[US_Circle] = true;
        isCurrency[DAI] = true;
        isCurrency[W_Ethereum] = true;
       // isCurrency[MST] = true;
        isCurrency[WBTC] = true;

        _currencies_by_address[US_Tether] = _currencies_hardcoded[CurrencyERC20.USDT];
        _currencies_by_address[US_Circle] = _currencies_hardcoded[CurrencyERC20.USDC];
        _currencies_by_address[DAI] = _currencies_hardcoded[CurrencyERC20.DAI];
    //    _currencies_by_address[MST] = _currencies_hardcoded[CurrencyERC20.MST];
        _currencies_by_address[W_Ethereum] = _currencies_hardcoded[CurrencyERC20.WETH];
        _currencies_by_address[WBTC] = _currencies_hardcoded[CurrencyERC20.WBTC];



        // AddCustomCurrency(US_Tether);
        // AddCustomCurrency(US_Circle);
        // AddCustomCurrency(DAI);
        // AddCustomCurrency(W_Ethereum);
        AddCustomCurrency(MST);
    }

    function get_hardcoded_currency(CurrencyERC20 currency)
        public
        view
        returns (IERC20Metadata)
    {
        return _currencies_hardcoded[currency];
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _contract contract address of a currency
    /// @return Documents the return variables of a contract’s function state variable
    // @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
    function checkCurrenciesBool(address _contract) public view returns (bool)
    {
        return isCurrency[_contract];
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param currency_contract address of a currency contract
    /// @return Documents the return variables of a contract’s function state variable
    // @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
    function getCurrencyByAddress(address currency_contract) public view returns (IERC20Metadata)
    {
        require(isCurrency[currency_contract] == true,"this address is not a currency");
        return _currencies_by_address[currency_contract];
    }


// TODO: add check that function call is a transfer
 /*
    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param data data of transaction (calldata)
    /// @return Documents the return variables of a contract’s function state variable
    function isTransfer(bytes calldata data) public returns (bool)
    {
        bytes calldata method_id = data[4:];
        if(method_id == _INTEFACE_ID_TRANSFER_ERC20)
         {
            return true;
         }
    }
*/

    /**
    *   Calculate fee (UnSafeMath) -- use it only if it ^0.8.0
    *   @param amount number from whom we take fee
    *   @param scale scale for rounding. 100 is 1/100 (percent). we can encreace scale if we want better division (like we need to take 0.5% instead of 5%, then scale = 1000)
    */
    function calculateFee(uint256 amount, uint256 scale) internal view returns (uint256) {
        uint a = amount / scale;
        uint b = amount % scale;
        uint c = promille_fee / scale;
        uint d = promille_fee % scale;
        return a * c * scale + a * d + b * c + (b * d + scale - 1) / scale;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(ICurrenciesERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
