module SelectedPublications
  RANK = {
    "first" => 0,
    "cofirst" => 1,
    "corresponding" => 2
  }.freeze

  def self.run(site)
    source = site.source
    input_path = File.join(source, "_bibliography", "papers.bib")
    output_path = File.join(source, "_bibliography", "selected.bib")
    stats_path = File.join(source, "_data", "publication_stats.yml")
    return unless File.exist?(input_path)

    entries = parse_entries(File.read(input_path))
    marked_entries = entries.filter_map do |entry|
      contribution = field(entry[:body], "contribution")
      next unless RANK.key?(contribution)

      year = field(entry[:body], "year").to_i
      entry.merge(rank: RANK[contribution], year: year, contribution: contribution)
    end

    selected = entries.filter_map do |entry|
      contribution = field(entry[:body], "contribution")
      next unless RANK.key?(contribution)
      next unless ccf_a_or_b?(entry[:body])

      year = field(entry[:body], "year").to_i
      entry.merge(rank: RANK[contribution], year: year)
    end

    selected.sort_by! { |entry| [-entry[:year], entry[:rank], entry[:index]] }
    content = selected.map { |entry| entry[:body].strip }.join("\n\n")
    File.write(output_path, "---\n---\n\n#{content}\n")
    File.write(stats_path, stats_yaml(marked_entries, selected))
  end

  def self.parse_entries(text)
    entries = []
    index = 0
    cursor = 0

    while (start_at = text.index("@", cursor))
      depth = 0
      end_at = nil
      seen_opening_brace = false

      text[start_at..].each_char.with_index(start_at) do |char, position|
        if char == "{"
          depth += 1
          seen_opening_brace = true
        end
        depth -= 1 if char == "}"
        if seen_opening_brace && depth.zero? && position > start_at
          end_at = position
          break
        end
      end

      break unless end_at

      entries << { body: text[start_at..end_at], index: index }
      index += 1
      cursor = end_at + 1
    end

    entries
  end

  def self.field(entry, name)
    match = entry.match(/^\s*#{Regexp.escape(name)}\s*=\s*\{([^}]*)\}/i)
    match && match[1].strip.downcase
  end

  def self.ccf_a_or_b?(entry)
    entry.match?(/CCF\s*-\s*[AB]/i)
  end

  def self.stats_yaml(marked_entries, selected)
    all_counts = counts(marked_entries)
    selected_counts = counts(selected)

    <<~YAML
      ---
      all:
        total: #{all_counts[:total]}
        first: #{all_counts[:first]}
        cofirst: #{all_counts[:cofirst]}
        corresponding: #{all_counts[:corresponding]}
      selected:
        total: #{selected_counts[:total]}
        first: #{selected_counts[:first]}
        cofirst: #{selected_counts[:cofirst]}
        corresponding: #{selected_counts[:corresponding]}
    YAML
  end

  def self.counts(entries)
    {
      total: entries.length,
      first: entries.count { |entry| field(entry[:body], "contribution") == "first" },
      cofirst: entries.count { |entry| field(entry[:body], "contribution") == "cofirst" },
      corresponding: entries.count { |entry| field(entry[:body], "contribution") == "corresponding" }
    }
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  SelectedPublications.run(site)
end
