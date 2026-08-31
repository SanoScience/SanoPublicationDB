module Authors
  module NameUtils
    module_function

    COLLECTIVE_KEYWORDS = %w[
      group team consortium initiative network collaboration committee society
      biobank investigators investigator study trial board association program programme
      institute center centre unit foundation panel registry working mission laboratory
    ].freeze

    TRUNCATION_PATTERNS = [
      /et\s+al\.?(?:\s*\([^)]*\))?/i,
      /\(\s*many others\s*\)/i,
      /\(\s*\.\.\.\s*\)/i,
      /\.{3,}/i,
      /additional authors not shown/i,
      /many others/i
    ].freeze

    TITLE_TOKENS = %w[
      prof professor dr md phd msc bsc mph dabr dabnm mr mrs ms
    ].freeze

    NAME_PARTICLES = %w[
      al ap ben bin da dal de del della der di dos du el la le van von ten ter den
    ].freeze

    def normalize_spacing(value)
      value.to_s.gsub(/[[:space:]]+/, " ").strip
    end

    def canonical(value)
      s = value.to_s.unicode_normalize(:nfkc)
      s = s.gsub(/[\u200B\u200C\u200D\uFEFF]/, "")
      s = s.tr("’`´", "'")
      s = s.tr("‐-‒–—−", "-")
      s = normalize_spacing(s)
      s = I18n.transliterate(s)
      s.downcase
    end

    def clean_word(word)
      word.to_s.strip.gsub(/\A[[:punct:]]+|[[:punct:]]+\z/, "")
    end

    def words(token)
      token.to_s.split(/\s+/).map(&:strip).reject(&:blank?)
    end

    def title_word?(word)
      TITLE_TOKENS.include?(clean_word(word).downcase)
    end

    def particle?(word)
      NAME_PARTICLES.include?(clean_word(word).downcase)
    end

    def extract_title_prefix(token)
      parts = words(token)
      title_parts = []

      while parts.any? && title_word?(parts.first)
        title_parts << parts.shift
      end

      [ normalize_spacing(title_parts.join(" ")), normalize_spacing(parts.join(" ")) ]
    end

    def last_name_start_index(parts)
      idx = parts.length - 1
      while idx > 0 && particle?(parts[idx - 1])
        idx -= 1
      end
      idx
    end

    def extract_first_and_last_name(body)
      parts = words(body)
      
      if parts.length >= 2
        split_index = last_name_start_index(parts)
        first_name = normalize_spacing(parts[0...split_index].join(" "))
        last_name  = normalize_spacing(parts[split_index..].join(" "))
      else
        first_name = ""
        last_name = normalize_spacing(body)
      end

      [first_name, last_name]
    end

    def collective_keyword?(token)
      downcased = canonical(token)
      COLLECTIVE_KEYWORDS.any? { |kw| downcased.match?(/\b#{Regexp.escape(kw)}\b/) }
    end

    def truncation_collective_token?(token)
      t = normalize_spacing(token)
      t.match?(/\Aet\s+al/i) || t.match?(/\Amany others\z/i) || t.match?(/\Aadditional authors not shown\z/i) || t.match?(/\A\.\.\.\z/) || t.match?(/\Aet\s+al\.\s+\(\s*\d+\s+additional authors not shown\s*\)\z/i)
    end

    def looks_like_collective?(token)
      t = normalize_spacing(token)
      truncation_collective_token?(t) || collective_keyword?(t)
    end
  end
end
