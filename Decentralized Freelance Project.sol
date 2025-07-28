// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Project {
    // Structure to represent a freelance project
    struct FreelanceProject {
        uint256 id;
        address client;
        address freelancer;
        string description;
        uint256 amount;
        uint256 deadline;
        ProjectStatus status;
        bool fundsReleased;
    }
    
    // Enum to track project status
    enum ProjectStatus {
        Open,
        Assigned,
        InProgress,
        Completed,
        Disputed
    }
    
    // State variables
    uint256 public projectCounter;
    mapping(uint256 => FreelanceProject) public projects;
    mapping(address => uint256[]) public clientProjects;
    mapping(address => uint256[]) public freelancerProjects;
    
    // Events
    event ProjectCreated(uint256 indexed projectId, address indexed client, uint256 amount);
    event ProjectAssigned(uint256 indexed projectId, address indexed freelancer);
    event ProjectCompleted(uint256 indexed projectId, address indexed freelancer);
    event FundsReleased(uint256 indexed projectId, address indexed freelancer, uint256 amount);
    
    // Modifiers
    modifier onlyClient(uint256 _projectId) {
        require(projects[_projectId].client == msg.sender, "Only client can perform this action");
        _;
    }
    
    modifier onlyFreelancer(uint256 _projectId) {
        require(projects[_projectId].freelancer == msg.sender, "Only assigned freelancer can perform this action");
        _;
    }
    
    modifier projectExists(uint256 _projectId) {
        require(_projectId < projectCounter, "Project does not exist");
        _;
    }
    
    /**
     * @dev Core Function 1: Create a new freelance project
     * @param _description Description of the project work
     * @param _deadline Unix timestamp for project deadline
     */
    function createProject(string memory _description, uint256 _deadline) external payable {
        require(msg.value > 0, "Project amount must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        
        uint256 projectId = projectCounter;
        
        projects[projectId] = FreelanceProject({
            id: projectId,
            client: msg.sender,
            freelancer: address(0),
            description: _description,
            amount: msg.value,
            deadline: _deadline,
            status: ProjectStatus.Open,
            fundsReleased: false
        });
        
        clientProjects[msg.sender].push(projectId);
        projectCounter++;
        
        emit ProjectCreated(projectId, msg.sender, msg.value);
    }
    
    /**
     * @dev Core Function 2: Assign project to a freelancer
     * @param _projectId ID of the project to assign
     * @param _freelancer Address of the freelancer to assign
     */
    function assignProject(uint256 _projectId, address _freelancer) 
        external 
        projectExists(_projectId) 
        onlyClient(_projectId) 
    {
        require(projects[_projectId].status == ProjectStatus.Open, "Project is not open for assignment");
        require(_freelancer != address(0), "Invalid freelancer address");
        require(_freelancer != projects[_projectId].client, "Client cannot be the freelancer");
        
        projects[_projectId].freelancer = _freelancer;
        projects[_projectId].status = ProjectStatus.Assigned;
        
        freelancerProjects[_freelancer].push(_projectId);
        
        emit ProjectAssigned(_projectId, _freelancer);
    }
    
    /**
     * @dev Core Function 3: Complete project and release funds
     * @param _projectId ID of the project to complete
     */
    function completeProject(uint256 _projectId) 
        external 
        projectExists(_projectId) 
        onlyClient(_projectId) 
    {
        FreelanceProject storage project = projects[_projectId];
        
        require(project.status == ProjectStatus.Assigned, "Project must be assigned to be completed");
        require(!project.fundsReleased, "Funds already released");
        require(project.freelancer != address(0), "No freelancer assigned");
        
        project.status = ProjectStatus.Completed;
        project.fundsReleased = true;
        
        // Transfer funds to freelancer
        payable(project.freelancer).transfer(project.amount);
        
        emit ProjectCompleted(_projectId, project.freelancer);
        emit FundsReleased(_projectId, project.freelancer, project.amount);
    }
    
    // View functions
    function getProject(uint256 _projectId) external view projectExists(_projectId) returns (FreelanceProject memory) {
        return projects[_projectId];
    }
    
    function getClientProjects(address _client) external view returns (uint256[] memory) {
        return clientProjects[_client];
    }
    
    function getFreelancerProjects(address _freelancer) external view returns (uint256[] memory) {
        return freelancerProjects[_freelancer];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
