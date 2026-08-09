# Discovery and Analysis Skill

## Overview

The Discovery and Analysis skill provides capabilities for analyzing existing codebases, parsing documentation, extracting technical standards, and documenting design systems for brown-field projects.

**Purpose**: Understand and document existing systems before making changes.

**Used By**: AI Solutions Architect, AI Design Orchestrator

## Core Capabilities

### 1. Codebase Analysis

**Folder Structure Analysis**:

- Scan directory tree
- Identify project organization patterns
- Map module dependencies
- Document folder conventions

**Technology Stack Detection**:

- Identify programming languages
- Detect frameworks and libraries
- Extract version information
- Identify build tools and CI/CD

**Dependency Analysis**:

- Parse package.json, requirements.txt, pom.xml, etc.
- Map internal module dependencies
- Identify external service dependencies
- Detect deprecated or outdated dependencies

### 2. Document Parsing

**Supported Formats**:

- **PDF**: Requirements docs, specifications, manuals
- **Microsoft Excel (.xlsx)**: Data models, test cases, feature lists
- **Microsoft Word (.docx)**: Requirements, design docs, user guides
- **Microsoft PowerPoint (.pptx)**: Architecture diagrams, presentations
- **Markdown (.md)**: READMEs, wikis, documentation

**Extraction Capabilities**:

- Text content extraction
- Table parsing
- Image and diagram extraction
- Metadata extraction
- Structure preservation

### 3. Code Standards Extraction

**Linting and Formatting**:

- ESLint configuration
- Prettier settings
- StyleLint rules
- Language-specific linters

**Naming Conventions**:

- Variable naming (camelCase, snake_case, PascalCase)
- File naming (kebab-case, PascalCase)
- Class and function naming
- Constant naming (UPPER_SNAKE_CASE)

**Code Organization**:

- Feature-based vs layer-based
- Module structure
- File placement patterns
- Import/export conventions

**Testing Standards**:

- Test framework (Jest, Mocha, PyTest, JUnit)
- Test file naming
- Coverage requirements
- Test organization

### 4. Design System Documentation

**Component Inventory**:

- Identify all UI components
- Document component variants
- Map component hierarchy
- Extract component props/API

**Visual Design Tokens**:

- Color palette (primary, secondary, background, text)
- Typography (font family, sizes, weights, line heights)
- Spacing system (margin, padding, grid)
- Border radius, shadows, transitions

**Layout Patterns**:

- Grid systems
- Responsive breakpoints
- Container widths
- Flexbox/Grid usage

**Accessibility Standards**:

- ARIA attributes
- Semantic HTML usage
- Keyboard navigation
- Color contrast ratios

## Analysis Patterns

### Pattern 1: Project Type Detection

```javascript
// React Detection
if (exists("package.json") && dependencies.includes("react")) {
  projectType = "React";
  if (dependencies.includes("next")) {
    framework = "Next.js";
  } else if (dependencies.includes("gatsby")) {
    framework = "Gatsby";
  }
}

// Vue Detection
if (dependencies.includes("vue")) {
  projectType = "Vue";
  if (dependencies.includes("nuxt")) {
    framework = "Nuxt.js";
  }
}

// Angular Detection
if (dependencies.includes("@angular/core")) {
  projectType = "Angular";
}

// Node.js Backend Detection
if (dependencies.includes("express")) {
  projectType = "Node.js";
  framework = "Express";
}

// Python Backend Detection
if (exists("requirements.txt") || exists("Pipfile")) {
  projectType = "Python";
  if (imports.includes("flask")) {
    framework = "Flask";
  } else if (imports.includes("django")) {
    framework = "Django";
  }
}
```

### Pattern 2: Architecture Pattern Recognition

**MVC Pattern**:

```
- controllers/ or routes/
- models/
- views/ or templates/
```

**Microservices Pattern**:

```
- services/
  - service-a/
  - service-b/
  - shared/
- docker-compose.yml or kubernetes/
```

**Layered Architecture**:

```
- presentation/
- application/
- domain/
- infrastructure/
```

**Feature-Based Organization**:

```
- features/
  - feature-a/
    - components/
    - services/
    - tests/
```

### Pattern 3: Design System Extraction

**Component Identification**:

```javascript
// React components
const components = findFiles("**/*.tsx", "**/*.jsx").filter((file) => {
  const content = readFile(file);
  return (
    content.includes("export") &&
    (content.includes("function") || content.includes("const"))
  );
});

// Vue components
const components = findFiles("**/*.vue");

// Angular components
const components = findFiles("**/*.component.ts");
```

**Color Extraction**:

```javascript
// From CSS/SCSS
const colors = extractFromCSS([
  "--primary-color",
  "--secondary-color",
  "--background-color",
  "--text-color",
]);

// From theme files
const theme = require("./theme.js");
const colors = theme.colors;

// From design tokens
const tokens = readJSON("design-tokens.json");
const colors = tokens.color;
```

## Document Parsing Strategies

### PDF Parsing

**Tools**:

- pdf-parse (Node.js)
- PyPDF2, pdfplumber (Python)

**Extraction**:

```javascript
// Extract text
const text = await parsePDF(filePath);

// Extract tables
const tables = await extractTables(filePath);

// Extract metadata
const metadata = {
  title: pdf.info.Title,
  author: pdf.info.Author,
  creationDate: pdf.info.CreationDate,
};
```

### Excel Parsing

**Tools**:

- xlsx (Node.js)
- openpyxl, pandas (Python)

**Extraction**:

```javascript
// Read workbook
const workbook = XLSX.readFile(filePath);

// Get all sheets
const sheets = workbook.SheetNames;

// Parse sheet to JSON
const data = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName]);

// Extract tables and data models
const dataModels = parseDataModels(data);
```

### Word Document Parsing

**Tools**:

- mammoth (Node.js)
- python-docx (Python)

**Extraction**:

```javascript
// Extract text with formatting
const result = await mammoth.convertToHtml({
  path: filePath,
});

// Extract plain text
const text = await mammoth.extractRawText({
  path: filePath,
});

// Extract tables
const tables = extractTablesFromWord(filePath);
```

### PowerPoint Parsing

**Tools**:

- pptx (Node.js)
- python-pptx (Python)

**Extraction**:

```javascript
// Extract slides
const presentation = await parsePPTX(filePath);

// Extract text from slides
const slideTexts = presentation.slides.map((slide) => slide.getText());

// Extract images/diagrams
const images = extractImages(presentation);
```

## Output Templates

### Codebase Summary Template

```markdown
# Codebase Summary

## Project Information

- **Project Type**: React Application
- **Language**: TypeScript
- **Framework**: React 18.2 + Vite

## Folder Structure
```

src/
├── components/
├── services/
├── utils/
└── App.tsx

```

## Technology Stack

### Frontend
- React 18.2.0
- TypeScript 5.0.0
- Material-UI 5.14.0

### Backend
- Node.js 18.x
- Express 4.18.x
- PostgreSQL 15.x

### Build Tools
- Vite 4.x
- ESLint, Prettier

## Dependencies
- Total: 45 dependencies
- Direct: 20 dependencies
- Dev: 25 dependencies

## Module Dependencies
[Mermaid diagram showing module relationships]
```

### Technical Standards Template

```markdown
# Technical Standards

## Code Style

- **Linter**: ESLint with Airbnb config
- **Formatter**: Prettier
- **Config**: .eslintrc.json, .prettierrc

## Naming Conventions

- **Variables**: camelCase
- **Functions**: camelCase
- **Classes**: PascalCase
- **Components**: PascalCase
- **Files**: kebab-case.tsx
- **Constants**: UPPER_SNAKE_CASE

## File Organization

- **Pattern**: Feature-based
- **Structure**: features/{feature-name}/

## Testing Standards

- **Framework**: Jest + React Testing Library
- **Coverage**: 80% minimum
- **Test Files**: {filename}.test.tsx

## API Conventions

- **Pattern**: RESTful
- **Versioning**: /api/v1
- **Response**: JSON with status codes
```

### Design System Template

```markdown
# Design System

## Color Palette

- **Primary**: #1976d2 (Blue)
- **Secondary**: #dc004e (Pink)
- **Background**: #f5f5f5 (Light Gray)
- **Text**: #212121 (Dark Gray)
- **Error**: #f44336 (Red)

## Typography

- **Font Family**: Roboto, sans-serif
- **Headings**:
  - H1: 2rem (32px), 600 weight
  - H2: 1.5rem (24px), 600 weight
  - H3: 1.25rem (20px), 500 weight
- **Body**: 1rem (16px), 400 weight

## Spacing System

- **Base Unit**: 8px
- **Scale**: 8, 16, 24, 32, 40, 48, 64

## Components

### Button

- Variants: primary, secondary, text
- Sizes: small, medium, large
- States: default, hover, active, disabled

### Card

- Variants: elevated, outlined
- Padding: 16px
- Border Radius: 4px
```

## Integration Points

### With Workflows

- **Foundation Workflow**: Primary user of this skill
- **Inception Workflow**: Uses extracted standards for NFRs
- **Construction Workflow**: Applies discovered patterns

### With Other Skills

- **architecture-design**: Feeds architecture findings
- **aidlc-core**: Applies analysis patterns
- **mermaid-diagramming**: Visualizes structure and dependencies

## Best Practices

### Codebase Analysis

1. **Start Broad, Then Deep**: Overall structure first, then details
2. **Identify Patterns**: Look for recurring patterns and conventions
3. **Note Inconsistencies**: Document deviations from standards
4. **Respect Privacy**: Don't extract sensitive data (credentials, keys)

### Document Parsing

1. **Verify Format**: Check file format before parsing
2. **Handle Errors**: Gracefully handle corrupted or invalid files
3. **Extract Metadata**: Capture document metadata (author, date)
4. **Preserve Structure**: Maintain heading hierarchy and organization

### Standards Extraction

1. **Prefer Configuration**: Extract from config files when possible
2. **Analyze Patterns**: Infer conventions from code patterns
3. **Document Gaps**: Note missing or incomplete standards
4. **Prioritize Critical**: Focus on most important standards first

## Success Criteria

- [ ] Project type correctly identified
- [ ] Tech stack completely documented
- [ ] Folder structure mapped
- [ ] Dependencies extracted
- [ ] Code standards documented
- [ ] Design system captured (if UI project)
- [ ] All documents parsed successfully
- [ ] Architecture patterns identified

## References

- Codebase analysis patterns
- Document parsing libraries
- Standards extraction techniques
- Design system documentation guide

---

_Discovery and Analysis Skill v1.0.0_
