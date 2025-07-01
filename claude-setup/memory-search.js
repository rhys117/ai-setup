#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const MEMORY_FILE = path.join(__dirname, 'dev-memory.json');

class MemorySearch {
  constructor() {
    this.memory = JSON.parse(fs.readFileSync(MEMORY_FILE, 'utf8'));
  }

  query(queryString) {
    const results = [];
    const query = this.parseQuery(queryString);
    
    for (const [category, entries] of Object.entries(this.memory.knowledge)) {
      for (const entry of entries) {
        if (this.matchesQuery(entry, query, category)) {
          results.push({ ...entry, category });
          // Update access tracking
          entry.accessed_count = (entry.accessed_count || 0) + 1;
          entry.last_accessed = new Date().toISOString();
        }
      }
    }
    
    // Save updated access counts
    this.saveMemory();
    
    return results;
  }

  parseQuery(queryString) {
    // Parse simple query syntax: "tags:auth", "category:testing", "context:middleware"
    const parts = queryString.split(/\s+AND\s+|\s+OR\s+/i);
    const operator = queryString.includes(' AND ') ? 'AND' : 'OR';
    
    return {
      operator,
      conditions: parts.map(part => {
        if (part.includes(':')) {
          const [field, value] = part.split(':');
          return { field: field.trim(), value: value ? value.trim() : '' };
        } else {
          // Full-text search
          return { field: 'fulltext', value: part.trim() };
        }
      })
    };
  }

  matchesQuery(entry, query, category) {
    const matches = query.conditions.map(condition => {
      switch (condition.field) {
        case 'tags':
          return entry.tags && entry.tags.some(tag => 
            tag.toLowerCase().includes(condition.value.toLowerCase())
          );
        case 'category':
          return category.toLowerCase().includes(condition.value.toLowerCase());
        case 'context':
          return entry.context && entry.context.toLowerCase().includes(condition.value.toLowerCase());
        case 'id':
          return entry.id === condition.value;
        case 'fulltext':
        default:
          // Full-text search across all text fields
          const searchText = [
            entry.context || '',
            entry.tags?.join(' ') || '',
            entry.examples?.join(' ') || '',
            entry.solution || ''
          ].join(' ').toLowerCase();
          return searchText.includes(condition.value.toLowerCase());
      }
    });

    return query.operator === 'AND' ? matches.every(m => m) : matches.some(m => m);
  }

  add(category, entry) {
    if (!this.memory.knowledge[category]) {
      this.memory.knowledge[category] = [];
    }
    
    entry.id = entry.id || `${category.slice(0,4)}-${String(Date.now()).slice(-3)}`;
    entry.created = entry.created || new Date().toISOString();
    entry.accessed_count = 0;
    entry.last_accessed = null;
    
    this.memory.knowledge[category].push(entry);
    this.memory.total_entries = Object.values(this.memory.knowledge)
      .reduce((sum, arr) => sum + arr.length, 0);
    this.memory.last_updated = new Date().toISOString();
    
    this.saveMemory();
    return entry;
  }

  getAllTags() {
    const tagCounts = {};
    const tagsByCategory = {};
    
    for (const [category, entries] of Object.entries(this.memory.knowledge)) {
      tagsByCategory[category] = new Set();
      
      for (const entry of entries) {
        if (entry.tags) {
          for (const tag of entry.tags) {
            tagCounts[tag] = (tagCounts[tag] || 0) + 1;
            tagsByCategory[category].add(tag);
          }
        }
      }
      
      // Convert Sets to sorted arrays
      tagsByCategory[category] = Array.from(tagsByCategory[category]).sort();
    }
    
    return {
      all: Object.keys(tagCounts).sort(),
      counts: tagCounts,
      byCategory: tagsByCategory,
      totalUnique: Object.keys(tagCounts).length,
      mostUsed: Object.entries(tagCounts)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 10)
        .map(([tag, count]) => ({ tag, count }))
    };
  }

  suggestTags(newTags) {
    const allTags = this.getAllTags().all;
    const suggestions = [];
    
    for (const newTag of newTags) {
      const similar = allTags.filter(existingTag => 
        existingTag.includes(newTag) || 
        newTag.includes(existingTag) ||
        this.calculateSimilarity(existingTag, newTag) > 0.6
      );
      
      if (similar.length > 0) {
        suggestions.push({
          proposed: newTag,
          existing: similar,
          recommendation: similar.length === 1 ? `Consider using existing tag: ${similar[0]}` : `Similar tags exist: ${similar.join(', ')}`
        });
      }
    }
    
    return suggestions;
  }

  calculateSimilarity(str1, str2) {
    const longer = str1.length > str2.length ? str1 : str2;
    const shorter = str1.length > str2.length ? str2 : str1;
    const editDistance = this.levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  levenshteinDistance(str1, str2) {
    const matrix = [];
    for (let i = 0; i <= str2.length; i++) {
      matrix[i] = [i];
    }
    for (let j = 0; j <= str1.length; j++) {
      matrix[0][j] = j;
    }
    
    for (let i = 1; i <= str2.length; i++) {
      for (let j = 1; j <= str1.length; j++) {
        if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j] + 1
          );
        }
      }
    }
    
    return matrix[str2.length][str1.length];
  }

  saveMemory() {
    fs.writeFileSync(MEMORY_FILE, JSON.stringify(this.memory, null, 2));
  }
}

// CLI interface
if (require.main === module) {
  const memory = new MemorySearch();
  const [,, command, ...args] = process.argv;

  switch (command) {
    case 'query':
      const results = memory.query(args.join(' '));
      console.log(JSON.stringify(results, null, 2));
      break;
      
    case 'add':
      const [category, entryJson] = args;
      const entry = JSON.parse(entryJson);
      
      // Check for similar tags before adding
      if (entry.tags) {
        const suggestions = memory.suggestTags(entry.tags);
        if (suggestions.length > 0) {
          console.log('\n⚠️  Tag suggestions:');
          suggestions.forEach(s => console.log(`  ${s.proposed}: ${s.recommendation}`));
          console.log('\nProceed with original tags? Add --force to skip this check\n');
          
          if (!args.includes('--force')) {
            process.exit(1);
          }
        }
      }
      
      const added = memory.add(category, entry);
      console.log(`✅ Added entry ${added.id} to ${category}`);
      break;
      
    case 'tags':
      const tagData = memory.getAllTags();
      const format = args[0] || 'summary';
      
      switch (format) {
        case 'all':
          console.log(JSON.stringify(tagData.all, null, 2));
          break;
        case 'counts':
          console.log(JSON.stringify(tagData.counts, null, 2));
          break;
        case 'category':
          console.log(JSON.stringify(tagData.byCategory, null, 2));
          break;
        case 'summary':
        default:
          console.log(`📊 Tag Summary:`);
          console.log(`Total unique tags: ${tagData.totalUnique}`);
          console.log(`\n🔥 Most used tags:`);
          tagData.mostUsed.forEach((item, i) => 
            console.log(`${i+1}. ${item.tag} (${item.count} entries)`)
          );
          console.log(`\n📂 Tags by category:`);
          Object.entries(tagData.byCategory).forEach(([cat, tags]) => 
            console.log(`${cat}: ${tags.slice(0, 5).join(', ')}${tags.length > 5 ? `... (+${tags.length - 5} more)` : ''}`)
          );
          break;
      }
      break;
      
    case 'suggest':
      const proposedTags = args;
      if (proposedTags.length === 0) {
        console.log('Usage: node memory-search.js suggest tag1 tag2 tag3');
        process.exit(1);
      }
      
      const suggestions = memory.suggestTags(proposedTags);
      if (suggestions.length === 0) {
        console.log('✅ No similar tags found - these look good to use!');
      } else {
        console.log('💡 Tag suggestions:');
        suggestions.forEach(s => console.log(`  ${s.proposed}: ${s.recommendation}`));
      }
      break;
      
    default:
      console.log('Memory Search Tool');
      console.log('');
      console.log('Usage:');
      console.log('  node memory-search.js query "tags:auth"              # Search entries');
      console.log('  node memory-search.js tags [summary|all|counts|category]  # List tags');
      console.log('  node memory-search.js suggest tag1 tag2             # Check tag similarity');
      console.log('  node memory-search.js add patterns \'{"tags":["new"],"context":"..."}\'  # Add entry');
      console.log('');
      console.log('Examples:');
      console.log('  node memory-search.js tags                          # Show tag summary');
      console.log('  node memory-search.js suggest authentication auth   # Check if tags are similar');
      console.log('  node memory-search.js query "category:testing"      # Find test-related entries');
  }
}

module.exports = MemorySearch;