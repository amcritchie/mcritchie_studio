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
    name: "Avi",
    slug: "avi",
    status: "active",
    agent_type: "product",
    title: "Product Owner",
    description: "Reviews PRs, tickets, and release candidates before production. Friendly, sharp, and a capable dev — the last set of eyes before Steffon ships.",
    avatar: "/agents/avi.png",
    position: 1
  },
  {
    name: "Carl",
    slug: "carl",
    status: "active",
    agent_type: "specialist",
    title: "Dev Backend Expert",
    description: "Crack Rails dev. Owns controllers, models, migrations, background jobs, ActiveRecord performance, and the studio-engine internals.",
    avatar: "/agents/carl.png",
    position: 2
  },
  {
    name: "Shannon",
    slug: "shannon",
    status: "active",
    agent_type: "specialist",
    title: "Dev UI Expert",
    description: "UI specialist. Owns frontend development across the ecosystem — ERB views, Tailwind, Alpine.js, theme system, and studio-engine UI primitives.",
    avatar: "/agents/shannon.png",
    position: 3
  },
  {
    name: "Jasper",
    slug: "jasper",
    status: "active",
    agent_type: "specialist",
    title: "Dev Blockchain Expert",
    description: "Blockchain specialist. Owns the Solana surface: turf-vault Anchor program, solana-studio Ruby client, and all on-chain integration.",
    avatar: "/agents/jasper.png",
    position: 4
  },
  {
    name: "Steffon",
    slug: "steffon",
    status: "active",
    agent_type: "specialist",
    title: "Infrastructure Expert",
    description: "Owns the DevOps surface — Heroku, deploys, env vars, CI, observability, recovery protocol. The agent who runs bin/deploy.",
    avatar: "/agents/steffon.png",
    position: 5
  },
  {
    name: "Turf Monster",
    slug: "turf-monster",
    status: "active",
    agent_type: "specialist",
    title: "Sports Domain Specialist",
    description: "Specializes in sports data, pick'em games, and the Turf Monster app. Expert in World Cup props and player stats.",
    avatar: "/agents/turf-monster.png",
    position: 6
  },
  {
    name: "Mack",
    slug: "mack",
    status: "active",
    agent_type: "worker",
    title: "General Worker",
    description: "Versatile worker agent handling data scraping, processing, and general-purpose tasks. Reliable and efficient.",
    avatar: "/agents/mack.png",
    position: 7
  },
  {
    name: "Mason",
    slug: "mason",
    status: "active",
    agent_type: "specialist",
    title: "Marketing",
    description: "Runs marketing — brand voice, launch comms, social, funnels, copy. (Previously held Infrastructure; that surface now belongs to Steffon.)",
    avatar: "/agents/mason.png",
    position: 8
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
  agent.update!(
    name: data[:name],
    agent_type: data[:agent_type],
    title: data[:title],
    description: data[:description],
    avatar: data[:avatar],
    position: data[:position]
  ) if agent.title != data[:title] ||
       agent.description != data[:description] ||
       agent.avatar != data[:avatar] ||
       agent.position != data[:position] ||
       agent.agent_type != data[:agent_type] ||
       agent.name != data[:name]
  puts "Agent: #{agent.name} (#{agent.agent_type}) — #{agent.title}"
  agent
end
