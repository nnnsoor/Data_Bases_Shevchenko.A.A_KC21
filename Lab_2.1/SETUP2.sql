USE Farm_Management_Shevchenko;
GO

IF OBJECT_ID('FERTILIZER_APPLICATION', 'U') IS NOT NULL DROP TABLE FERTILIZER_APPLICATION;
IF OBJECT_ID('WORKER_EQUIPMENT_SKILL', 'U') IS NOT NULL DROP TABLE WORKER_EQUIPMENT_SKILL;
IF OBJECT_ID('WORKER', 'U') IS NOT NULL DROP TABLE WORKER;
IF OBJECT_ID('EQUIPMENT', 'U') IS NOT NULL DROP TABLE EQUIPMENT;
IF OBJECT_ID('LAND_PLOT', 'U') IS NOT NULL DROP TABLE LAND_PLOT;
IF OBJECT_ID('FERTILIZER', 'U') IS NOT NULL DROP TABLE FERTILIZER;
IF OBJECT_ID('CROP', 'U') IS NOT NULL DROP TABLE CROP;
IF OBJECT_ID('BRIGADE', 'U') IS NOT NULL DROP TABLE BRIGADE;
GO

CREATE TABLE BRIGADE (
    brigade_id INT PRIMARY KEY,
    foreman_first_name VARCHAR(50) NOT NULL,
    foreman_last_name VARCHAR(50) NOT NULL,
    foreman_patronymic VARCHAR(50) NULL,
    formation_date DATE NULL
);

CREATE TABLE CROP (
    crop_id INT PRIMARY KEY,
    crop_name VARCHAR(100) NOT NULL UNIQUE,
    average_yield DECIMAL(10,2) NOT NULL,
    requires_irrigation BIT NOT NULL,
    growing_season_days INT NULL
);

CREATE TABLE FERTILIZER (
    fertilizer_id INT PRIMARY KEY,
    fertilizer_name VARCHAR(100) NOT NULL UNIQUE,
    fertilizer_type VARCHAR(50) NOT NULL,
    nitrogen_percent DECIMAL(5,2) NULL,
    phosphorus_percent DECIMAL(5,2) NULL,
    potassium_percent DECIMAL(5,2) NULL,
    application_rate DECIMAL(10,2) NULL
);

CREATE TABLE LAND_PLOT (
    plot_id INT PRIMARY KEY,
    area DECIMAL(10,2) NOT NULL,
    has_irrigation BIT NOT NULL,
    soil_quality_index DECIMAL(3,1) NULL,
    brigade_id INT NOT NULL,
    crop_id INT NULL,
    CONSTRAINT FK_LAND_PLOT_BRIGADE FOREIGN KEY (brigade_id) REFERENCES BRIGADE(brigade_id),
    CONSTRAINT FK_LAND_PLOT_CROP FOREIGN KEY (crop_id) REFERENCES CROP(crop_id)
);

CREATE TABLE WORKER (
    worker_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50) NULL,
    hire_date DATE NOT NULL,
    phone_number VARCHAR(20) NULL,
    brigade_id INT NOT NULL,
    CONSTRAINT FK_WORKER_BRIGADE FOREIGN KEY (brigade_id) REFERENCES BRIGADE(brigade_id)
);

CREATE TABLE EQUIPMENT (
    equipment_id INT PRIMARY KEY,
    equipment_type VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    manufacture_year INT NULL,
    purchase_date DATE NULL,
    status VARCHAR(20) NULL,
    brigade_id INT NOT NULL,
    CONSTRAINT FK_EQUIPMENT_BRIGADE FOREIGN KEY (brigade_id) REFERENCES BRIGADE(brigade_id)
);

CREATE TABLE WORKER_EQUIPMENT_SKILL (
    skill_id INT PRIMARY KEY,
    worker_id INT NOT NULL,
    equipment_id INT NOT NULL,
    skill_level VARCHAR(20) NULL,
    certification_date DATE NULL,
    experience_years INT NULL,
    CONSTRAINT FK_SKILL_WORKER FOREIGN KEY (worker_id) REFERENCES WORKER(worker_id),
    CONSTRAINT FK_SKILL_EQUIPMENT FOREIGN KEY (equipment_id) REFERENCES EQUIPMENT(equipment_id),
    CONSTRAINT UQ_WORKER_EQUIPMENT UNIQUE (worker_id, equipment_id)
);

CREATE TABLE FERTILIZER_APPLICATION (
    application_id INT PRIMARY KEY,
    plot_id INT NOT NULL,
    fertilizer_id INT NOT NULL,
    worker_id INT NOT NULL,
    brigade_id INT NOT NULL,
    application_date DATE NOT NULL,
    amount_kg DECIMAL(10,2) NOT NULL,
    application_method VARCHAR(50) NULL,
    notes VARCHAR(500) NULL,
    CONSTRAINT FK_APPLICATION_PLOT FOREIGN KEY (plot_id) REFERENCES LAND_PLOT(plot_id),
    CONSTRAINT FK_APPLICATION_FERTILIZER FOREIGN KEY (fertilizer_id) REFERENCES FERTILIZER(fertilizer_id),
    CONSTRAINT FK_APPLICATION_WORKER FOREIGN KEY (worker_id) REFERENCES WORKER(worker_id),
    CONSTRAINT FK_APPLICATION_BRIGADE FOREIGN KEY (brigade_id) REFERENCES BRIGADE(brigade_id)
);
GO