// contracts/TokenVester.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

// solmate  dependencies
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/src/utils/ReentrancyGuard.sol";
// OpenZeppelin dependencies
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title TokenVesting
 * @author Owlen
 * @notice ### ERC20 Token Vesting Scheduler
 *
 * **A smart contract that manages multiple vesting schedules for a single ERC20 token.**
 *
 * The contract should be sent ERC20 tokens, and then vesting schedules can be set to determine the rate of their release
 * to a beneficiary.
 *
 * Only the contract owner can add schedules with `scheduleCreate()`.
 *
 * Only the beneficiary and the contract owner can `scheduleRelease()` vested tokens to the beneficiary.
 *
 * The contract keeps track and "locks" the amount tokens prmissed to all schedules,
 * so they can't be withdrawn from the contract with the `vesterWithdraw()` function.
 *
 * The contract limits a purposely low limit of `MAX_SCHEDULES_PER_BENEFICIARY` schedules per beneficiary.
 *
 * The contract owner can `scheduleRevoke()` schedules that are created as revocable.
 * This action will release all of the vested tokens to the beneficiary, but will effectively cancel the schedule from that
 * point forward, unlocking the unvested tokens.
 *
 * The contract owner can `vesterPause()` and `vesterUnpause()` from the contract.
 * **note:** revoking a schedule is allowed when distribution is paused, which *will* release vested tokens.
 *
 * @dev The release mechanism is based on a linear function based on time.
 * You can override `_computeReleasableAmount()` to create different release algorithms.
 */
contract TokenVester is Owned, ReentrancyGuard, Pausable {
    struct Schedule {
        // beneficiary of tokens after they are released
        address beneficiary;
        // start time of the vesting schedule in seconds since epoch
        uint32 startTime;
        // cliff time in seconds
        uint32 cliffTime;
        // end time of the vesting schedule
        uint32 endTime;
        // duration of a slice period for the vesting in seconds
        uint32 sliceDuration;
        // whether or not the vesting is revocable
        bool revocable;
        // total amount of tokens to be released at the end of the vesting
        uint256 totalAmount; //TODO change to uint64
        // amount of tokens released
        uint256 released; //TODO change to uint64
        // whether or not the vesting has been revoked
        bool revoked;
    }

    // address of the ERC20 token
    ERC20 private immutable _token;

    uint8 public constant MAX_SCHEDULES_PER_BENEFICIARY = 32; // Limit on purpose
    bytes6[] private _scheduleIds;
    mapping(bytes6 => Schedule) private _schedules;
    mapping(address => uint8) private _beneficiaryScheduleCount;
    uint256 private _totalLockedTokens; // Tokens acounted for in all un-revoked schedules

    /**
     * @dev Emitted when Schedule is created
     */
    event ScheduleCreated(bytes6 scheduleId, uint256 schedulesCount);

    /**
     * @dev Emitted when unlocked tokens are withdrawn
     */
    event withdrawUnlockedTokens(uint256 amount, uint256 withdrawableAmount);

    /**
     * @dev Emitted when a schedule is released to the beneficiary
     */
    event ScheduleReleased(
        bytes6 scheduleId,
        address beneficiary,
        uint256 releasedAmount
    );

    /**
     * @dev Emitted when a schedule is revoked.
     */
    event ScheduleRevoked(
        bytes6 scheduleId,
        uint256 releasedAmount,
        uint256 returnedAmount
    );

    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     */
    modifier whenNotRevoked(bytes6 scheduleId) {
        require(
            !_schedules[scheduleId].revoked,
            "TokenVester: Schedule is Revoked"
        );
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     */
    constructor(address token_) Owned(msg.sender) {
        // Check that the token address is not 0x0.
        require(
            token_ != address(0x0),
            "TokenVester: token address can't be 0x0"
        );
        // Set the token address.
        _token = ERC20(token_);
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param startTime start time of the vesting schedule (in seconds since epoch)
     * @param cliffTime cliff time of the vesting schedule
     * @param endTime end time of the vesting schedule
     * @param slicePeriodSec duration of a slice period for the vesting in seconds
     * @param revocable whether the vesting is revocable or not
     * @param amount total amount of tokens to be released at the end of the vesting
     *
     * @notice Emits `ScheduleCreated` event on success
     */
    function scheduleCreate(
        address beneficiary,
        uint32 startTime,
        uint32 cliffTime,
        uint32 endTime,
        uint32 slicePeriodSec,
        bool revocable,
        uint256 amount
    ) external onlyOwner whenNotPaused {
        require(
            beneficiary > address(0x0),
            "TokenVester: beneficiary address can't be zero"
        );
        require(
            getVesterUnlockedAmount() >= amount,
            "TokenVester: not enough available tokens to vest"
        );
        require(
            endTime > startTime,
            "TokenVester: endTime must be higher than startTime"
        );
        require(
            endTime >= cliffTime && cliffTime >= startTime,
            "TokenVester: times do not adhere to endTime GE cliffTime GE StartTime "
        );
        require(amount > 0, "TokenVester: amount must be higher than zero");
        require(
            slicePeriodSec > 0,
            "TokenVester: slicePeriodSeconds must be higher than zero"
        );
        require(
            slicePeriodSec <= endTime - startTime,
            "TokenVester: slicePeriodSeconds can not be higher than the scedule duration"
        );
        require(
            _beneficiaryScheduleCount[beneficiary] <
                MAX_SCHEDULES_PER_BENEFICIARY,
            "TokenVester: max Schedules per benefiuciary reached"
        );
        bytes6 scheduleId = _computeScheduleIdForAddressAndIndex(
            beneficiary,
            _beneficiaryScheduleCount[beneficiary]
        );
        _schedules[scheduleId] = Schedule(
            beneficiary,
            startTime,
            cliffTime,
            endTime,
            slicePeriodSec,
            revocable,
            amount,
            0, // None released
            false // Not revoked
        );
        _totalLockedTokens += amount;
        _scheduleIds.push(scheduleId);
        _beneficiaryScheduleCount[beneficiary] += 1;
        emit ScheduleCreated(scheduleId, _scheduleIds.length);
    }

    /**
     * @notice Revokes the vesting schedule for given identifier. *This is not reversable!*
     *
     *          It first releases all the tokens that are already vested to the beneficiary.
     *
     *          The unvested tokens would never be released, so they are removed from the locked amount.
     *
     *          **Note:** revokeschedule() *can* be used when the contract is paused.
     *
     *          Emits `ScheduleRevoked` event on success.
     *
     * @param scheduleId the vesting schedule identifier to be revoked
     */
    function scheduleRevoke(
        bytes6 scheduleId
    ) external onlyOwner whenNotRevoked(scheduleId) {
        Schedule storage schedule = _schedules[scheduleId];
        require(
            schedule.beneficiary > address(0x0),
            "TokenVester: schedule not found"
        );
        require(
            schedule.revocable,
            "TokenVester: vesting schedule is not revocable"
        );
        uint256 releaseableAmount = _computeReleasableAmount(schedule);
        if (releaseableAmount > 0) {
            scheduleReleaseVested(scheduleId, releaseableAmount);
        }
        uint256 notRleasable = schedule.totalAmount - schedule.released;
        _totalLockedTokens -= notRleasable; // These would never be released
        schedule.revoked = true;
        emit ScheduleRevoked(scheduleId, releaseableAmount, notRleasable);
    }

    /**
     * @notice Release the vested amount of tokens to the beneficiary.
     * Can be called by the beneficiary or the owner.
     * Emits `ScheduleReleased` event on success.
     * @param scheduleId the vesting schedule identifier
     * @param releaseAmount the amount of tokens to release
     */
    function scheduleReleaseVested(
        bytes6 scheduleId,
        uint256 releaseAmount
    ) public nonReentrant whenNotPaused whenNotRevoked(scheduleId) {
        Schedule storage schedule = _schedules[scheduleId];
        require(
            schedule.beneficiary > address(0x0),
            "TokenVester: schedule not found"
        );

        require(
            (msg.sender == schedule.beneficiary) || (msg.sender == owner),
            "TokenVester: only beneficiary or owner can release vested tokens"
        );

        assert(_computeReleasableAmount(schedule) >= releaseAmount);
        schedule.released += releaseAmount;
        address payable beneficiaryPayable = payable(schedule.beneficiary);
        _totalLockedTokens -= releaseAmount;
        // transfer tokens
        SafeTransferLib.safeTransfer(_token, beneficiaryPayable, releaseAmount);
        emit ScheduleReleased(scheduleId, schedule.beneficiary, releaseAmount);
    }

    /**
     * @notice Wrapper around `scheduleRelease()` to release **all** the of the vested tokens to the beneficiary.
     * @param scheduleId the vesting schedule identifier
     */
    function scheduleReleaseAllVesteed(
        bytes6 scheduleId
    ) public whenNotPaused whenNotRevoked(scheduleId) {
        scheduleReleaseVested(
            scheduleId,
            _computeReleasableAmount(_schedules[scheduleId])
        );
    }

    /**
     * @dev Returns the number of vesting schedules associated with a beneficiary.
     * @param _beneficiary address of the beneficiary
     * @return the number of vesting schedules for the beneficiary
     */
    function getBeneficiarySchedulesCount(
        address _beneficiary
    ) external view returns (uint256) {
        return _beneficiaryScheduleCount[_beneficiary];
    }

    /**
     * @dev Returns the vesting schedule id at the given index.
     * @return the vesting id
     */
    function getScheduleIdAtIndex(
        uint256 index
    ) external view returns (bytes6) {
        require(
            index < getSchedulesCount(),
            "TokenVester: index out of bounds"
        );
        return _scheduleIds[index];
    }

    /**
     * @notice Returns the vesting schedule information for a given beneficiary and index.
     * @param _beneficiary address of the beneficiary
     * @return the vesting schedule structure information
     */
    function getScheduleByAddressAndIndex(
        address _beneficiary,
        uint256 index
    ) external view returns (bytes6) {
        require(
            index < _beneficiaryScheduleCount[_beneficiary],
            "TokenVester: index out of bounds"
        );
        return _computeScheduleIdForAddressAndIndex(_beneficiary, index);
    }

    /**
     * @notice Returns the vesting schedule information for a given scheduleId.
     * @param scheduleId the scheduleId to be computed
     * @return the vesting schedule structure information
     */
    function getScheduleInfo(
        bytes6 scheduleId
    ) public view returns (Schedule memory) {
        Schedule storage schedule = _schedules[scheduleId];
        require(
            schedule.beneficiary > address(0x0),
            "TokenVester: schedule not found"
        );

        return schedule;
    }

    /**
     * @notice Computes the vested amount of tokens for a given scheduleId.
     * @param scheduleId the scheduleId to be computed
     * @return the vested amount
     */
    function getScheduleComputeReleasableAmount(
        bytes6 scheduleId
    ) external view whenNotRevoked(scheduleId) returns (uint256) {
        Schedule storage schedule = _schedules[scheduleId];
        require(
            schedule.beneficiary > address(0x0),
            "TokenVester: schedule not found"
        );

        return _computeReleasableAmount(schedule);
    }

    /**
     * @dev Computes the schedule ID for an address and an index.
     * @param _beneficiary address of the beneficiary
     * @param index the index
     */
    function _computeScheduleIdForAddressAndIndex(
        address _beneficiary,
        uint256 index
    ) private pure returns (bytes6) {
        return bytes6(keccak256(abi.encodePacked(_beneficiary, index)));
    }

    /**
     * @dev Computes the releasable amount of tokens for a schedule, based on a linear time function.
     *      This method can be overridden with different strategies to create non-linear or other release schedules.
     *      **Note:** The time percision is based on sliceDurations, so vesting is effectively gorwing every sliceDuration.
     * @param schedule the schedule
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(
        Schedule memory schedule
    ) internal view virtual returns (uint256) {
        // Retrieve the current time.
        uint32 currentTime = uint32(block.timestamp);
        // If the current time is before the cliff or revoked, no tokens are releasable.
        if ((currentTime < schedule.cliffTime) || schedule.revoked) {
            return 0;
        }
        // If the current time is after the vesting end time, all vested tokens are releasable,
        // minus the amount already released.
        else if (currentTime >= schedule.endTime) {
            return schedule.totalAmount - schedule.released;
        }
        // Otherwise, some tokens are releasable, pro rated based on time.
        else {
            // Total number of seconds to vest
            uint32 totalSeconds = schedule.endTime - schedule.startTime;
            // Number of whole vested slices that have elapsed
            uint32 vestedSlices = (currentTime - schedule.startTime) /
                schedule.sliceDuration;
            // Number of seconds vested of full vesting slices
            uint32 vestedSeconds = vestedSlices * schedule.sliceDuration;
            // Compute the amount of tokens that are vested based on vested seconds
            uint256 vestedAmount = (schedule.totalAmount * vestedSeconds) /
                totalSeconds;

            // Subtract the amount already released and return.
            return vestedAmount - schedule.released;
        }
    }

    /**
     * @notice Pauses the ability to create new schedules or release vested tokens.
     */
    function vesterPause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Brings back the ability to create new schedules and release vested tokens.
     */
    function vesterUnpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Returns the total amount of vesting schedules.
     * @return the total amount of vesting schedules
     */
    function getVesterLockedAmount() external view returns (uint256) {
        return _totalLockedTokens;
    }

    /**
     * @dev Returns the total amount of tokens not locked in the contract that can be withdrawn.
     * @return the amount of tokens available to withdraw from the contract
     */
    function getVesterUnlockedAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)) - _totalLockedTokens;
    }

    /**
     * @notice Withdraw the specified amount of tokens back to the Owner, if available.
     *         Emits `withdrawUnlockedTokens` event on success.
     * @param amount the amount to withdraw
     *
     */
    function vesterWithdraw(uint256 amount) external nonReentrant onlyOwner {
        uint256 withdrawableAmount = getVesterUnlockedAmount();
        require(
            withdrawableAmount >= amount,
            "TokenVester: not enough withdrawable funds"
        );
        SafeTransferLib.safeTransfer(_token, msg.sender, amount);
        emit withdrawUnlockedTokens(amount, withdrawableAmount);
    }

    /**
     * @dev Returns the address of the ERC20 token managed by the vesting contract.
     */
    function getToken() external view returns (address) {
        return address(_token);
    }

    /**
     * @dev Returns the number of schedules managed by this contract.
     * @return the number of vesting schedules
     */
    function getSchedulesCount() public view returns (uint256) {
        return _scheduleIds.length;
    }

    /**
     * @notice Transfer ownership
     * @param newOwner the new owner
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /**
     * @dev This function is called for plain Ether transfers, i.e. for every call with empty calldata.
     */
    receive() external payable {}

    /**
     * @dev Fallback function is executed if none of the other functions match the function
     * identifier or no data was provided with the function call.
     */
    fallback() external payable {}
}
