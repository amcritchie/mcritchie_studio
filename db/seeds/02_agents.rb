agents_data = [
  {
    name: "Alex",
    slug: "alex",
    status: "active",
    agent_type: "orchestrator",
    title: "Lead Orchestrator",
    description: "Coordinates all agents, manages task assignment, and oversees system operations. The central brain of McRitchie Studio.",
    avatar: "/agents/alex.png",
    position: 0
  },
  {
    name: "Turf Monster",
    slug: "turf-monster",
    status: "active",
    agent_type: "specialist",
    title: "Sports Domain Specialist",
    description: "Specializes in sports data, pick'em games, and the Turf Monster app. Expert in World Cup props and player stats.",
    avatar: "/agents/turf-monster.png",
    position: 1
  },
  {
    name: "Mason",
    slug: "mason",
    status: "active",
    agent_type: "specialist",
    title: "Infrastructure Specialist",
    description: "Handles infrastructure, deployments, monitoring, and system maintenance. Keeps everything running smoothly.",
    avatar: "/agents/mason.png",
    position: 2
  },
  {
    name: "Mack",
    slug: "mack",
    status: "active",
    agent_type: "worker",
    title: "General Worker",
    description: "Versatile worker agent handling data scraping, processing, and general-purpose tasks. Reliable and efficient.",
    avatar: "/agents/mack.png",
    position: 3
  }
]

agents_data.map do |data|
  agent = Agent.find_or_create_by!(slug: data[:slug]) do |a|
    a.name = data[:name]
    a.status = data[:status]
    a.agent_type = data[:agent_type]
    a.title = data[:title]
    a.description = data[:description]
    a.avatar = data[:avatar]
    a.position = data[:position]
  end
  agent.update!(avatar: data[:avatar], position: data[:position]) if agent.avatar != data[:avatar] || agent.position != data[:position]
  puts "Agent: #{agent.name} (#{agent.agent_type})"
  agent
end
