const Voting = artifacts.require("./Voting.sol");

contract("Voting", accounts => {
  it("...test initial current status should be 0", async () => {
    const votingInstance = await Voting.deployed();

    const currStatus = await votingInstance.getCurrentWFStatus();

    assert.equal(currStatus, 0, "The initial value must be 0");
  });


  // others tests here
  
});
