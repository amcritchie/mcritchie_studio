module LineupLabelsHelper
  # Display label for a Roster#offense_starting_12 slot. Depth numbers are
  # dropped (depth is implied by left-to-right order). Flex slots derive their
  # label from the picked player's actual position so the badge communicates
  # what role filled the slot (TE for a 2nd TE in flex, WR for a 4th WR, etc).
  def offense_slot_label(slot, pick = nil)
    case slot
    when :qb              then "QB"
    when :rb              then "RB"
    when :wr1, :wr2, :wr3 then "WR"
    when :te              then "TE"
    when :flex
      return "—" unless pick
      %w[RB FB HB].include?(pick.position) ? "RB" : pick.position
    when :lt, :lg, :c, :rg, :rt then slot.to_s.upcase
    end
  end

  # Display label for a Roster#defense_starting_12 slot.
  def defense_slot_label(slot, pick = nil)
    case slot
    when :edge1, :edge2 then "EG"
    when :dl1, :dl2     then "DL"
    when :dl_flex
      return "—" unless pick
      %w[EDGE DE].include?(pick.position) ? "EG" : "DL"
    when :lb1, :lb2     then "LB"
    when :ss            then "SS"
    when :fs            then "FS"
    when :cb1, :cb2     then "CB"
    when :flex
      return "—" unless pick
      pick.position == "CB" ? "CB" : "S"
    end
  end
end
